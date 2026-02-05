package auth

import (
	"context"
	"errors"
	"sync"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

type otpSession struct {
	hash      string
	expiresAt time.Time
	verified  bool
}

var otpStore sync.Map

type Repository struct {
	DB *pgxpool.Pool
}

func (r *Repository) SaveOTP(ctx context.Context, phone, hash string) error {
	session := otpSession{
		hash:      hash,
		expiresAt: time.Now().Add(5 * time.Minute),
		verified:  false,
	}
	otpStore.Store(phone, session)
	return nil
}

func (r *Repository) GetOTP(ctx context.Context, phone string) (string, error) {
	val, ok := otpStore.Load(phone)
	if !ok {
		return "", errors.New("otp not found")
	}
	session := val.(otpSession)
	if time.Now().After(session.expiresAt) {
		otpStore.Delete(phone)
		return "", errors.New("otp expired")
	}
	return session.hash, nil
}

func (r *Repository) MarkOTPVerified(ctx context.Context, phone string) error {
	val, ok := otpStore.Load(phone)
	if !ok {
		return errors.New("otp not found")
	}
	session := val.(otpSession)
	session.verified = true
	otpStore.Store(phone, session)
	return nil
}

func (r *Repository) IsOTPValid(ctx context.Context, phone string) (string, error) {
	val, ok := otpStore.Load(phone)
	if !ok {
		return "", errors.New("otp not found")
	}
	session := val.(otpSession)
	if session.verified || time.Now().After(session.expiresAt) {
		return "", errors.New("otp invalid or expired")
	}
	return session.hash, nil
}

func (r *Repository) GetValidOTPHash(ctx context.Context, phone string) (string, error) {
	return r.IsOTPValid(ctx, phone)
}

func (r *Repository) MarkOTPUsed(ctx context.Context, phone string) error {
	return r.MarkOTPVerified(ctx, phone)
}
