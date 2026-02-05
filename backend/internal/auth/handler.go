package auth

import (
	"log"
	"net/http"

	"github.com/dchest/captcha"
	"github.com/gin-gonic/gin"
)

type Handler struct {
	Service     *Service
	CitizenRepo CitizenRepo
}

/* ---------- SEND OTP ---------- */

func (h *Handler) SendOTP(c *gin.Context) {
	var req OTPRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}

	if !captcha.VerifyString(req.CaptchaID, req.CaptchaValue) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid captcha"})
		return
	}

	if err := h.Service.SendOTP(c, req.PhoneNumber); err != nil {
		c.Error(err) // 👈 force Gin to log it
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": err.Error(), // TEMP: expose real error
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "OTP sent successfully"})
}

/* ---------- VERIFY OTP ---------- */

func (h *Handler) VerifyOTP(c *gin.Context) {
	var req OTPVerifyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}

	token, err := h.Service.VerifyOTPAndLogin(
		c,
		req.PhoneNumber,
		req.Code,
		h.CitizenRepo,
	)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}

	log.Printf("✅ Citizen logged in: Phone=%s, Token generated", req.PhoneNumber)

	c.JSON(http.StatusOK, gin.H{
		"token": token,
		"role":  "CITIZEN",
	})
	log.Println("JWT_TOKEN_FULL:", token)
}
