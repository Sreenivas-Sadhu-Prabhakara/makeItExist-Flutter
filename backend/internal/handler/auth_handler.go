package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/makeitexist/backend/internal/domain"
)

// AuthHandler handles authentication endpoints
type AuthHandler struct {
	authService domain.UserService
}

// NewAuthHandler creates a new auth handler
func NewAuthHandler(authService domain.UserService) *AuthHandler {
	return &AuthHandler{authService: authService}
}

// GoogleLogin handles Google SSO login
// POST /api/v1/auth/google
func (h *AuthHandler) GoogleLogin(c *gin.Context) {
	var req domain.SSOLoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "validation_error",
			"message": "id_token is required",
		})
		return
	}

	resp, err := h.authService.SSOLogin(c.Request.Context(), &req)
	if err != nil {
		status := http.StatusUnauthorized
		c.JSON(status, gin.H{
			"error":   "sso_login_failed",
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Login successful",
		"data":    resp,
	})
}

// FirebaseLogin handles multi-provider Firebase auth (Google, Facebook, Microsoft)
// POST /api/v1/auth/firebase
func (h *AuthHandler) FirebaseLogin(c *gin.Context) {
	var req domain.FirebaseAuthRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "validation_error",
			"message": "id_token and provider are required",
		})
		return
	}

	// Validate provider
	if req.Provider != "google" && req.Provider != "facebook" && req.Provider != "microsoft" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "validation_error",
			"message": "provider must be google, facebook, or microsoft",
		})
		return
	}

	resp, err := h.authService.FirebaseLogin(c.Request.Context(), &req)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error":   "firebase_login_failed",
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Login successful",
		"data":    resp,
	})
}

// Login handles admin password-based login (fallback)
// POST /api/v1/auth/login
func (h *AuthHandler) Login(c *gin.Context) {
	var req domain.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "validation_error",
			"message": err.Error(),
		})
		return
	}

	resp, err := h.authService.Login(c.Request.Context(), &req)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error":   "login_failed",
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Login successful",
		"data":    resp,
	})
}

// GetProfile returns the authenticated user's profile
// GET /api/v1/auth/profile
func (h *AuthHandler) GetProfile(c *gin.Context) {
	userIDStr, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	parsedID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_user_id",
			"message": "Invalid user ID format",
		})
		return
	}

	user, err := h.authService.GetProfile(c.Request.Context(), parsedID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"error":   "not_found",
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{"data": user})
}
