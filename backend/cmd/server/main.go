package main

import (
	"log"

	"civic-complaint-system/backend/config"
	"civic-complaint-system/backend/internal/auth"
	"civic-complaint-system/backend/internal/citizen"
	"civic-complaint-system/backend/internal/common/db"
	"civic-complaint-system/backend/internal/common/middleware"
	"civic-complaint-system/backend/internal/common/utils"
	"civic-complaint-system/backend/internal/complaint"
	"civic-complaint-system/backend/internal/ml"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {

	// Load .env
	_ = godotenv.Load()

	cfg := config.LoadConfig()
	middleware.SetJWTSecret(cfg.JWTSecret)

	// Set JWT secret
	utils.SetJWTSecret(cfg.JWTSecret)

	// Connect DB
	pg, err := db.Connect(db.DBConfig{
		Host: cfg.DBHost,
		Port: cfg.DBPort,
		Name: cfg.DBName,
		User: cfg.DBUser,
		Pass: cfg.DBPass,
	})
	if err != nil {
		log.Fatal("❌ DB connection failed:", err)
	}
	log.Println("✅ PostgreSQL connected successfully")

	// Complaint module
	mlClient := ml.NewClient(cfg.MLServiceURL)
	complaintRepo := &complaint.Repository{DB: pg}
	complaintService := &complaint.Service{Repo: complaintRepo}
	complaintHandler := &complaint.Handler{
		Service:  complaintService,
		MLClient: mlClient,
	}

	// Init SNS (using mock for testing - replace with real AWS SNS when credentials are set)
	snsClient := &auth.MockSNSSender{}
	log.Println("✅ Mock SNS initialized (for testing - OTP will be logged)")

	// Repositories
	authRepo := &auth.Repository{DB: pg}
	citizenRepo := &citizen.Repository{DB: pg}

	// Services
	authService := &auth.Service{
		Repo: authRepo,
		SNS:  snsClient,
	}

	// Handlers
	authHandler := &auth.Handler{
		Service:     authService,
		CitizenRepo: citizenRepo,
	}

	// HTTP server
	r := gin.Default()
	r.Use(middleware.CORSMiddleware())
	r.Static("/uploads", "./uploads")

	api := r.Group("/api")
	// PUBLIC ROUTES
	authRoutes := api.Group("/auth")
	auth.RegisterRoutes(authRoutes, authHandler)
	authRoutes.POST("/citizen/verify-otp", authHandler.VerifyOTP)
	citizenHandler := &citizen.Handler{Repo: citizenRepo}
	// PROTECTED ROUTES
	citizenRoutes := api.Group("/citizen")
	citizenRoutes.Use(middleware.JWTAuthMiddleware())

	citizenRoutes.GET("/home", citizenHandler.CitizenHome)
	citizenRoutes.POST("/complaints", complaintHandler.RaiseComplaint)
	citizenRoutes.GET("/complaints", complaintHandler.GetComplaints)
	citizenRoutes.POST("/complaints/:id/feedback", complaintHandler.SubmitFeedback)
	citizenRoutes.POST("/predict", complaintHandler.Predict)

	log.Println("🚀 Server running on http://localhost:8080")
	r.Run(":8080")
}
