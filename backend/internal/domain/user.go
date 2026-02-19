package domain

import (
	"context"
	"time"

	"github.com/google/uuid"
)

// Role represents user roles in the system
type Role string

const (
	RoleStudent Role = "student"
	RoleBuilder Role = "builder"
	RoleAdmin   Role = "admin"
)

// User represents an AIM student or admin
type User struct {
	ID           uuid.UUID `json:"id"`
	Email        string    `json:"email"`
	PasswordHash string    `json:"-"`
	FullName     string    `json:"full_name"`
	StudentID    string    `json:"student_id"`
	Role         Role      `json:"role"`
	IsVerified   bool      `json:"is_verified"`
	OTP          string    `json:"-"`
	OTPExpiresAt time.Time `json:"-"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

// SSOLoginRequest is the input for Google SSO login
type SSOLoginRequest struct {
	IDToken string `json:"id_token" binding:"required"`
}

// LoginRequest is the input for admin password login (fallback)
type LoginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

// AuthResponse is the output after successful auth
type AuthResponse struct {
	Token        string `json:"token"`
	RefreshToken string `json:"refresh_token"`
	User         User   `json:"user"`
}

// UserRepository defines the interface for user data access
type UserRepository interface {
	Create(ctx context.Context, user *User) error
	FindByEmail(ctx context.Context, email string) (*User, error)
	FindByID(ctx context.Context, id uuid.UUID) (*User, error)
	Update(ctx context.Context, user *User) error
	UpdatePassword(ctx context.Context, userID uuid.UUID, passwordHash string) error
	SetOTP(ctx context.Context, email, otp string, expiresAt time.Time) error
	VerifyOTP(ctx context.Context, email, otp string) error
	List(ctx context.Context, limit, offset int) ([]User, int, error)
}

// UserService defines the interface for user business logic
type UserService interface {
	SSOLogin(ctx context.Context, req *SSOLoginRequest) (*AuthResponse, error)
	Login(ctx context.Context, req *LoginRequest) (*AuthResponse, error)
	GetProfile(ctx context.Context, userID uuid.UUID) (*User, error)
	AdminResetPassword(ctx context.Context, targetUserID uuid.UUID, newPassword string) error
	ListUsers(ctx context.Context, limit, offset int) ([]User, int, error)
	CreateOrUpdateAdmin(ctx context.Context, user *User) error
}
