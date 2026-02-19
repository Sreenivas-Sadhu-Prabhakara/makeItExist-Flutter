package main

import (
	"context"
	"fmt"
	"os"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"golang.org/x/crypto/bcrypt"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: go run add_admin.go <DATABASE_URL>")
		os.Exit(1)
	}
	connStr := os.Args[1]
	ctx := context.Background()
	pool, err := pgxpool.New(ctx, connStr)
	if err != nil {
		fmt.Printf("Failed to connect to database: %v\n", err)
		os.Exit(1)
	}
	defer pool.Close()

	id := uuid.New()
	email := "admin"
	password := "admin"
	fullName := "Administrator"
	studentID := ""
	role := "admin"
	isVerified := true
	createdAt := time.Now()
	updatedAt := time.Now()

	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		fmt.Printf("Failed to hash password: %v\n", err)
		os.Exit(1)
	}

	query := `INSERT INTO users (id, email, password_hash, full_name, student_id, role, is_verified, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
		ON CONFLICT (email) DO UPDATE SET password_hash = EXCLUDED.password_hash, role = EXCLUDED.role, is_verified = EXCLUDED.is_verified, updated_at = EXCLUDED.updated_at`
	_, err = pool.Exec(ctx, query, id, email, string(hash), fullName, studentID, role, isVerified, createdAt, updatedAt)
	if err != nil {
		fmt.Printf("Failed to insert/update admin user: %v\n", err)
		os.Exit(1)
	}
	fmt.Println("Admin user 'admin' created/updated successfully.")
}
