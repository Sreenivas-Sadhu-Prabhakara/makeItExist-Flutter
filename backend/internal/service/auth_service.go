package service

import (
	"context"
	"crypto/rand"
	"errors"
	"fmt"
	"math/big"
	"net/smtp"
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

func (s *authService) Register(ctx context.Context, req *domain.RegisterRequest) (*domain.AuthResponse, error) {
	// Validate AIM email domain
	if !strings.HasSuffix(strings.ToLower(req.Email), "@"+s.cfg.AIM.EmailDomain) {
		return nil, errors.New("only AIM student emails are allowed (must end with @" + s.cfg.AIM.EmailDomain + ")")
	}

	// Check if user already exists
	existing, err := s.userRepo.FindByEmail(ctx, req.Email)
	if err != nil {
		return nil, fmt.Errorf("failed to check existing user: %w", err)
	}
	if existing != nil {
		return nil, errors.New("user already registered with this email")
	}

	// Hash password
	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, fmt.Errorf("failed to hash password: %w", err)
	}

	// Create user
	user := &domain.User{
		ID:           uuid.New(),
		Email:        strings.ToLower(req.Email),
		PasswordHash: string(hash),
		FullName:     req.FullName,
		StudentID:    req.StudentID,
		Role:         domain.RoleStudent,
		IsVerified:   false,
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}

	if err := s.userRepo.Create(ctx, user); err != nil {
		return nil, fmt.Errorf("failed to create user: %w", err)
	}

	// Generate and send OTP
	otp, err := generateOTP(s.cfg.OTP.Length)
	if err != nil {
		return nil, fmt.Errorf("failed to generate OTP: %w", err)
	}

	expiresAt := time.Now().Add(time.Duration(s.cfg.OTP.ExpiryMinutes) * time.Minute)
	if err := s.userRepo.SetOTP(ctx, user.Email, otp, expiresAt); err != nil {
		return nil, fmt.Errorf("failed to set OTP: %w", err)
	}

	// Send OTP via email
	if err := s.sendOTPEmail(user.Email, user.FullName, otp); err != nil {
		log.Warn().Err(err).Str("email", user.Email).Msg("Failed to send OTP email — logging OTP for dev fallback")
	}
	log.Info().Str("email", user.Email).Str("otp", otp).Msg("OTP generated")

	// Generate JWT tokens
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

func (s *authService) Login(ctx context.Context, req *domain.LoginRequest) (*domain.AuthResponse, error) {
	user, err := s.userRepo.FindByEmail(ctx, strings.ToLower(req.Email))
	if err != nil {
		return nil, fmt.Errorf("failed to find user: %w", err)
	}
	if user == nil {
		return nil, errors.New("invalid email or password")
	}

	// Verify password
	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		return nil, errors.New("invalid email or password")
	}

	// Block unverified users
	if !user.IsVerified {
		return nil, errors.New("email not verified — check your inbox for the verification code")
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

func (s *authService) VerifyOTP(ctx context.Context, req *domain.VerifyOTPRequest) error {
	return s.userRepo.VerifyOTP(ctx, req.Email, req.OTP)
}

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

// JWT Claims
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

func generateOTP(length int) (string, error) {
	otp := ""
	for i := 0; i < length; i++ {
		n, err := rand.Int(rand.Reader, big.NewInt(10))
		if err != nil {
			return "", err
		}
		otp += n.String()
	}
	return otp, nil
}

// sendOTPEmail sends the 6-digit verification code to the user via SMTP.
func (s *authService) sendOTPEmail(toEmail, fullName, otp string) error {
	smtpHost := s.cfg.SMTP.Host
	smtpPort := s.cfg.SMTP.Port
	smtpUser := s.cfg.SMTP.User
	smtpPass := s.cfg.SMTP.Password

	if smtpUser == "" || smtpPass == "" {
		log.Warn().Msg("SMTP credentials not configured — skipping email send")
		return nil
	}

	from := smtpUser
	subject := "Make It Exist — Email Verification Code"
	body := fmt.Sprintf(
		"Hi %s,\r\n\r\n"+
			"Your verification code is: %s\r\n\r\n"+
			"This code expires in %d minutes.\r\n\r\n"+
			"If you didn't sign up for Make It Exist, please ignore this email.\r\n\r\n"+
			"— Make It Exist Team 🚀",
		fullName, otp, s.cfg.OTP.ExpiryMinutes,
	)

	msg := fmt.Sprintf(
		"From: Make It Exist <%s>\r\n"+
			"To: %s\r\n"+
			"Subject: %s\r\n"+
			"MIME-Version: 1.0\r\n"+
			"Content-Type: text/plain; charset=UTF-8\r\n"+
			"\r\n%s",
		from, toEmail, subject, body,
	)

	auth := smtp.PlainAuth("", smtpUser, smtpPass, smtpHost)
	addr := smtpHost + ":" + smtpPort

	if err := smtp.SendMail(addr, auth, from, []string{toEmail}, []byte(msg)); err != nil {
		return fmt.Errorf("smtp send failed: %w", err)
	}
	log.Info().Str("to", toEmail).Msg("📧 Verification email sent")
	return nil
}

// ResendOTP generates a new OTP and re-sends the verification email.
func (s *authService) ResendOTP(ctx context.Context, email string) error {
	user, err := s.userRepo.FindByEmail(ctx, strings.ToLower(email))
	if err != nil {
		return fmt.Errorf("failed to find user: %w", err)
	}
	if user == nil {
		return errors.New("user not found")
	}
	if user.IsVerified {
		return errors.New("email already verified")
	}

	otp, err := generateOTP(s.cfg.OTP.Length)
	if err != nil {
		return fmt.Errorf("failed to generate OTP: %w", err)
	}

	expiresAt := time.Now().Add(time.Duration(s.cfg.OTP.ExpiryMinutes) * time.Minute)
	if err := s.userRepo.SetOTP(ctx, user.Email, otp, expiresAt); err != nil {
		return fmt.Errorf("failed to set OTP: %w", err)
	}

	if err := s.sendOTPEmail(user.Email, user.FullName, otp); err != nil {
		log.Warn().Err(err).Str("email", user.Email).Msg("Failed to send OTP email")
	}
	log.Info().Str("email", user.Email).Str("otp", otp).Msg("OTP resent")
	return nil
}
