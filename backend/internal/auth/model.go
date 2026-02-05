package auth

type OTPRequest struct {
	PhoneNumber  string `json:"phone_number" binding:"required"`
	CaptchaID    string `json:"captcha_id" binding:"required"`
	CaptchaValue string `json:"captcha_value" binding:"required"`
}

type OTPVerifyRequest struct {
	PhoneNumber string `json:"phone_number" binding:"required"`
	Code        string `json:"code" binding:"required"`
}
