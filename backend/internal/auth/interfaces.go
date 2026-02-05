package auth

import "context"

type CitizenRepo interface {
	GetOrCreateCitizen(ctx context.Context, phone string) (string, error)
}
