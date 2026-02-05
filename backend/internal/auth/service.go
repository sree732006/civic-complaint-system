package auth

import (
	"context"
	"errors"
	"fmt"
	"math/rand"
	"time"
	"log"

	"civic-complaint-system/backend/internal/common/crypto"
	"civic-complaint-system/backend/internal/common/utils"
)

type Service struct {
	Repo *Repository
	SNS  SNSSender
}

/* ---------- OTP GENERATOR ---------- */

func generateOTP() string {
	rand.Seed(time.Now().UnixNano())
	otp := fmt.Sprintf("%06d", rand.Intn(1000000))
	return otp
}


/* ---------- SEND OTP ---------- */

func (s *Service) SendOTP(ctx context.Context, phone string) error {
	otp := generateOTP()

	log.Println("OTP GENERATED:", otp)

	hash, err := crypto.HashOTP(otp)
	if err != nil {
		return err
	}

	err = s.Repo.SaveOTP(ctx, phone, hash)
	if err != nil {
		log.Println("❌ SAVE OTP ERROR:", err)
		return err
	}

	log.Println("✅ OTP SAVED FOR:", phone)

	message := "Your OTP for Civic Complaint System is: " + otp

	err = s.SNS.SendSMS(phone, message)
	if err != nil {
		log.Println("❌ SNS SEND ERROR:", err)
		return err
	}

	log.Println("📨 OTP SMS REQUEST SENT TO SNS")

	return nil
}
func normalizePhone(phone string) string {
	if len(phone) == 10 {
		return "+91" + phone
	}
	return phone
}


/* ---------- VERIFY OTP + LOGIN ---------- */

func (s *Service) VerifyOTPAndLogin(
	ctx context.Context,
	phone string,
	code string,
	citizenRepo CitizenRepo,
) (string, error) {

	hash, err := s.Repo.GetValidOTPHash(ctx, phone)
	if err != nil {
		return "", errors.New("otp expired or not found")
	}

	if !crypto.VerifyOTP(hash, code) {
		return "", errors.New("invalid otp")
	}

	_ = s.Repo.MarkOTPUsed(ctx, phone)

	userID, err := citizenRepo.GetOrCreateCitizen(ctx, phone)
	if err != nil {
		return "", err
	}

	return utils.GenerateJWT(userID, "CITIZEN")
}
