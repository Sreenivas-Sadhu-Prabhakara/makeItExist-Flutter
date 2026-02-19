package service

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/makeitexist/backend/internal/config"
	"github.com/makeitexist/backend/internal/domain"
	"github.com/rs/zerolog/log"
	"golang.org/x/crypto/bcrypt"
)

type authService struct {
	userRepo domain.UserRepository
	cfg      *config.Config
}

// NewAuthService creates a new authentication service
func NewAuthService(userRepo domain.UserRepository, cfg *config.Config) domain.UserService {
	return &authService{
		userRepo: userRepo,
		cfg:      cfg,
	}
}

// ---------------------------------------------------------------------------
// Google ID-token verification
// ---------------------------------------------------------------------------

// googleTokenInfo represents the response from Google's tokeninfo endpoint.
type googleTokenInfo struct {
	Email         string `json:"email"`
	EmailVerified string `json:"email_verified"`
	Name          string `json:"name"`
	Picture       string `json:"picture"`
	Aud           string `json:"aud"`
	Iss           string `json:"iss"`
	Sub           string `json:"sub"`
	Error         string `json:"error_description"`
}

// verifyGoogleIDToken calls Google's tokeninfo endpoint to validate an ID token.
func verifyGoogleIDToken(idToken string) (*googleTokenInfo, error) {
	resp, err := http.Get("https://oauth2.googleapis.com/tokeninfo?id_token=" + idToken)
	if err != nil {
		return nil, fmt.Errorf("failed to call Google tokeninfo: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read Google response: %w", err)
	}

	var info googleTokenInfo
	if err := json.Unmarshal(body, &info); err != nil {
		return nil, fmt.Errorf("failed to parse Google response: %w", err)
	}

	if info.Error != "" {
		return nil, fmt.Errorf("Google token error: %s", info.Error)
	}

	// Validate issuer
	if info.Iss != "accounts.google.com" && info.Iss != "https://accounts.google.com" {
		return nil, errors.New("invalid token issuer")
	}

	return &info, nil
}

// ---------------------------------------------------------------------------
// SSO Login (primary auth method — Google Sign-In)
// ---------------------------------------------------------------------------

// SSOLogin verifies a Google ID token, finds or creates the user, and returns JWT tokens.
func (s *authService) SSOLogin(ctx context.Context, req *domain.SSOLoginRequest) (*domain.AuthResponse, error) {
	// Verify Google ID token
	tokenInfo, err := verifyGoogleIDToken(req.IDToken)
	if err != nil {
		return nil, fmt.Errorf("invalid Google token: %w", err)
	}

	// Validate audience (client ID) if configured
	if s.cfg.Google.ClientID != "" && tokenInfo.Aud != s.cfg.Google.ClientID {
		return nil, errors.New("token audience mismatch — check GOOGLE_CLIENT_ID configuration")
	}

	// Validate email is verified by Google
	if tokenInfo.EmailVerified != "true" {
		return nil, errors.New("email not verified by Google")
	}

	email := strings.ToLower(tokenInfo.Email)

	// Check allowed domains
	allowed := false
	for _, d := range s.cfg.Google.AllowedDomains {
		d = strings.TrimSpace(d)
		if strings.HasSuffix(email, "@"+d) {
			allowed = true
			break
		}
	}
	if !allowed {
		return nil, fmt.Errorf("email domain not allowed — must be one of: %s",
			strings.Join(s.cfg.Google.AllowedDomains, ", "))
	}

	// Find existing user or auto-create
	user, err := s.userRepo.FindByEmail(ctx, email)
	if err != nil {
		return nil, fmt.Errorf("failed to look up user: %w", err)
	}

	if user == nil {
		// Auto-create new user from Google profile
		user = &domain.User{
			ID:           uuid.New(),
			Email:        email,
			PasswordHash: "", // no password for SSO users
			FullName:     tokenInfo.Name,
			StudentID:    "",
			Role:         domain.RoleStudent,
			IsVerified:   true,
			CreatedAt:    time.Now(),
			UpdatedAt:    time.Now(),
		}
		if err := s.userRepo.Create(ctx, user); err != nil {
			return nil, fmt.Errorf("failed to create user: %w", err)
		}
		log.Info().Str("email", email).Str("name", tokenInfo.Name).Msg("🆕 New SSO user created")
	}

	// Generate JWT tokens
	token, err := s.generateToken(user)
	if err != nil {
		return nil, fmt.Errorf("failed to generate token: %w", err)
	}

	refreshToken, err := s.generateRefreshToken(user)
	if err != nil {
		return nil, fmt.Errorf("failed to generate refresh token: %w", err)
	}

	log.Info().Str("email", email).Msg("✅ SSO login successful")

	return &domain.AuthResponse{
		Token:        token,
		RefreshToken: refreshToken,
		User:         *user,
	}, nil
}

// ---------------------------------------------------------------------------
// Password Login (admin fallback)
// ---------------------------------------------------------------------------

// Login handles admin password-based login.
func (s *authService) Login(ctx context.Context, req *domain.LoginRequest) (*domain.AuthResponse, error) {
	user, err := s.userRepo.FindByEmail(ctx, strings.ToLower(req.Email))
	if err != nil {
		return nil, fmt.Errorf("failed to find user: %w", err)
	}
	if user == nil {
		return nil, errors.New("invalid email or password")
	}

	// SSO-only accounts cannot use password login
	if user.PasswordHash == "" {
		return nil, errors.New("this account uses Google SSO — please sign in with Google")
	}

	// Verify password
	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		return nil, errors.New("invalid email or password")
	}

	// Generate tokens
	token, err := s.generateToken(user)
	if err != nil {
		return nil, fmt.Errorf("failed to generate token: %w", err)
	}

	refreshToken, err := s.generateRefreshToken(user)
	if err != nil {
		return nil, fmt.Errorf("failed to generate refresh token: %w", err)
	}

	return &domain.AuthResponse{
		Token:        token,
		RefreshToken: refreshToken,
		User:         *user,
	}, nil
}

// ---------------------------------------------------------------------------
// Profile & Admin
// ---------------------------------------------------------------------------

func (s *authService) GetProfile(ctx context.Context, userID uuid.UUID) (*domain.User, error) {
	user, err := s.userRepo.FindByID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to find user: %w", err)
	}
	if user == nil {
		return nil, errors.New("user not found")
	}
	return user, nil
}

func (s *authService) AdminResetPassword(ctx context.Context, targetUserID uuid.UUID, newPassword string) error {
	user, err := s.userRepo.FindByID(ctx, targetUserID)
	if err != nil {
		return fmt.Errorf("failed to find user: %w", err)
	}
	if user == nil {
		return errors.New("user not found")
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(newPassword), bcrypt.DefaultCost)
	if err != nil {
		return fmt.Errorf("failed to hash password: %w", err)
	}

	if err := s.userRepo.UpdatePassword(ctx, targetUserID, string(hash)); err != nil {
		return fmt.Errorf("failed to update password: %w", err)
	}

	log.Info().Str("target_user", user.Email).Msg("Admin reset password")
	return nil
}

func (s *authService) ListUsers(ctx context.Context, limit, offset int) ([]domain.User, int, error) {
	return s.userRepo.List(ctx, limit, offset)
}

// ---------------------------------------------------------------------------
// JWT helpers
// ---------------------------------------------------------------------------

// Claims represents JWT token claims
type Claims struct {
	UserID string      `json:"user_id"`
	Email  string      `json:"email"`
	Role   domain.Role `json:"role"`
	jwt.RegisteredClaims
}

func (s *authService) generateToken(user *domain.User) (string, error) {
	claims := &Claims{
		UserID: user.ID.String(),
		Email:  user.Email,
		Role:   user.Role,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(s.cfg.JWT.Expiry)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			Issuer:    "makeitexist",
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(s.cfg.JWT.Secret))
}

func (s *authService) generateRefreshToken(user *domain.User) (string, error) {
	claims := &Claims{
		UserID: user.ID.String(),
		Email:  user.Email,
		Role:   user.Role,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(s.cfg.JWT.RefreshExpiry)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			Issuer:    "makeitexist-refresh",
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(s.cfg.JWT.Secret))
}
