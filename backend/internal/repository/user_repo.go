package repository

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/makeitexist/backend/internal/domain"
)

type userRepo struct {
	db *pgxpool.Pool
}

// NewUserRepository creates a new user repository
func NewUserRepository(db *pgxpool.Pool) domain.UserRepository {
	return &userRepo{db: db}
}

func (r *userRepo) Create(ctx context.Context, user *domain.User) error {
	query := `
		INSERT INTO users (id, email, password_hash, full_name, student_id, role, is_verified, provider, provider_id, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
	`
	_, err := r.db.Exec(ctx, query,
		user.ID, user.Email, user.PasswordHash, user.FullName,
		user.StudentID, user.Role, user.IsVerified, user.Provider, user.ProviderID,
		user.CreatedAt, user.UpdatedAt,
	)
	return err
}

func (r *userRepo) FindByEmail(ctx context.Context, email string) (*domain.User, error) {
	query := `
		SELECT id, email, password_hash, full_name, student_id, role, 
		       is_verified, otp, otp_expires_at, provider, provider_id, created_at, updated_at
		FROM users WHERE email = $1
	`
	user := &domain.User{}
	var otp *string
	var otpExpires *time.Time
	err := r.db.QueryRow(ctx, query, email).Scan(
		&user.ID, &user.Email, &user.PasswordHash, &user.FullName,
		&user.StudentID, &user.Role, &user.IsVerified,
		&otp, &otpExpires, &user.Provider, &user.ProviderID, &user.CreatedAt, &user.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}
	if otp != nil {
		user.OTP = *otp
	}
	if otpExpires != nil {
		user.OTPExpiresAt = *otpExpires
	}
	return user, nil
}

func (r *userRepo) FindByID(ctx context.Context, id uuid.UUID) (*domain.User, error) {
	query := `
		SELECT id, email, password_hash, full_name, student_id, role, 
		       is_verified, provider, provider_id, created_at, updated_at
		FROM users WHERE id = $1
	`
	user := &domain.User{}
	err := r.db.QueryRow(ctx, query, id).Scan(
		&user.ID, &user.Email, &user.PasswordHash, &user.FullName,
		&user.StudentID, &user.Role, &user.IsVerified,
		&user.Provider, &user.ProviderID,
		&user.CreatedAt, &user.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}
	return user, nil
}

func (r *userRepo) Update(ctx context.Context, user *domain.User) error {
	query := `
		UPDATE users SET full_name=$1, role=$2, is_verified=$3, provider=$4, provider_id=$5, updated_at=$6
		WHERE id=$7
	`
	_, err := r.db.Exec(ctx, query,
		user.FullName, user.Role, user.IsVerified, user.Provider, user.ProviderID,
		user.UpdatedAt, user.ID,
	)
	return err
}

func (r *userRepo) UpdatePassword(ctx context.Context, userID uuid.UUID, passwordHash string) error {
	query := `UPDATE users SET password_hash=$1, updated_at=$2 WHERE id=$3`
	_, err := r.db.Exec(ctx, query, passwordHash, time.Now(), userID)
	return err
}

func (r *userRepo) SetOTP(ctx context.Context, email, otp string, expiresAt time.Time) error {
	query := `UPDATE users SET otp=$1, otp_expires_at=$2, updated_at=$3 WHERE email=$4`
	_, err := r.db.Exec(ctx, query, otp, expiresAt, time.Now(), email)
	return err
}

func (r *userRepo) VerifyOTP(ctx context.Context, email, otp string) error {
	query := `
		UPDATE users SET is_verified=true, otp=NULL, otp_expires_at=NULL, updated_at=$1
		WHERE email=$2 AND otp=$3 AND otp_expires_at > $4
	`
	result, err := r.db.Exec(ctx, query, time.Now(), email, otp, time.Now())
	if err != nil {
		return err
	}
	if result.RowsAffected() == 0 {
		return errors.New("invalid or expired OTP")
	}
	return nil
}

func (r *userRepo) List(ctx context.Context, limit, offset int) ([]domain.User, int, error) {
	countQuery := `SELECT COUNT(*) FROM users`
	var total int
	if err := r.db.QueryRow(ctx, countQuery).Scan(&total); err != nil {
		return nil, 0, err
	}

	query := `
		SELECT id, email, full_name, student_id, role, is_verified, created_at, updated_at
		FROM users ORDER BY created_at DESC LIMIT $1 OFFSET $2
	`
	rows, err := r.db.Query(ctx, query, limit, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var users []domain.User
	for rows.Next() {
		var u domain.User
		if err := rows.Scan(
			&u.ID, &u.Email, &u.FullName, &u.StudentID,
			&u.Role, &u.IsVerified, &u.CreatedAt, &u.UpdatedAt,
		); err != nil {
			return nil, 0, err
		}
		users = append(users, u)
	}
	return users, total, nil
}
