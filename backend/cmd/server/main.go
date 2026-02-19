package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/makeitexist/backend/internal/config"
	"github.com/makeitexist/backend/internal/handler"
	"github.com/makeitexist/backend/internal/repository"
	"github.com/makeitexist/backend/internal/router"
	"github.com/makeitexist/backend/internal/service"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
)

func main() {
	// Setup structured logging
	zerolog.TimeFieldFormat = zerolog.TimeFormatUnix
	log.Logger = log.Output(zerolog.ConsoleWriter{Out: os.Stderr})

	log.Info().Msg("🚀 Starting Make It Exist API Server...")

	// Load configuration
	cfg := config.Load()
	log.Info().
		Str("port", cfg.Server.Port).
		Str("env", cfg.Server.Env).
		Msg("Configuration loaded")

	// Connect to PostgreSQL
	ctx := context.Background()
	poolConfig, err := pgxpool.ParseConfig(cfg.Database.DSN())
	if err != nil {
		log.Fatal().Err(err).Msg("Failed to parse database config")
	}
	poolConfig.MaxConns = int32(cfg.Database.MaxConnections)
	poolConfig.MinConns = int32(cfg.Database.MaxIdleConnections)
	poolConfig.MaxConnLifetime = cfg.Database.ConnectionMaxLifetime

	db, err := pgxpool.NewWithConfig(ctx, poolConfig)
	if err != nil {
		log.Fatal().Err(err).Msg("Failed to connect to database")
	}
	defer db.Close()

	// Ping database
	if err := db.Ping(ctx); err != nil {
		log.Fatal().Err(err).Msg("Failed to ping database")
	}
	log.Info().Msg("✅ Connected to PostgreSQL")

	// Auto-run migrations
	runMigrations(ctx, db)

	// Initialize repositories
	userRepo := repository.NewUserRepository(db)
	requestRepo := repository.NewBuildRequestRepository(db)
	scheduleRepo := repository.NewScheduleRepository(db)

	// Initialize services
	authService := service.NewAuthService(userRepo, cfg)
	requestService := service.NewRequestService(requestRepo, userRepo)
	scheduleService := service.NewScheduleService(scheduleRepo, requestRepo)

	// Initialize handlers
	authHandler := handler.NewAuthHandler(authService)
	requestHandler := handler.NewRequestHandler(requestService)
	scheduleHandler := handler.NewScheduleHandler(scheduleService)
	adminHandler := handler.NewAdminHandler(requestService, scheduleService, authService)

	// Setup router
	r := router.Setup(cfg, authHandler, requestHandler, scheduleHandler, adminHandler)

	// Auto-generate weekend slots for next 8 weeks
	go func() {
		if err := scheduleService.AutoGenerateWeekendSlots(ctx, 8); err != nil {
			log.Warn().Err(err).Msg("Failed to auto-generate weekend slots")
		} else {
			log.Info().Msg("📅 Weekend slots auto-generated for next 8 weeks")
		}
	}()

	// Create HTTP server with timeouts
	srv := &http.Server{
		Addr:         fmt.Sprintf(":%s", cfg.Server.Port),
		Handler:      r,
		ReadTimeout:  cfg.Server.ReadTimeout,
		WriteTimeout: cfg.Server.WriteTimeout,
	}

	// Start server in goroutine
	go func() {
		log.Info().Str("addr", srv.Addr).Msg("🌐 Server listening")
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatal().Err(err).Msg("Server failed")
		}
	}()

	// Graceful shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Info().Msg("⏳ Shutting down server...")

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := srv.Shutdown(shutdownCtx); err != nil {
		log.Fatal().Err(err).Msg("Server forced to shutdown")
	}

	log.Info().Msg("👋 Server stopped gracefully")
}

// runMigrations executes the SQL migration file if the users table doesn't exist yet.
func runMigrations(ctx context.Context, db *pgxpool.Pool) {
	// Check if migrations already applied (users table exists)
	var exists bool
	err := db.QueryRow(ctx,
		`SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'users')`).Scan(&exists)
	if err != nil {
		log.Warn().Err(err).Msg("Could not check migration status")
		return
	}
	if exists {
		log.Info().Msg("📦 Database tables already exist, skipping migration")
		return
	}

	// Try to read and execute migration file
	migrationPaths := []string{
		"migrations/001_initial_schema.up.sql",    // Docker / production
		"../migrations/001_initial_schema.up.sql",  // local dev from cmd/server
	}
	var sqlBytes []byte
	for _, p := range migrationPaths {
		sqlBytes, err = os.ReadFile(p)
		if err == nil {
			break
		}
	}
	if err != nil {
		log.Warn().Msg("Migration file not found — tables must be created manually")
		return
	}

	if _, err := db.Exec(ctx, string(sqlBytes)); err != nil {
		log.Fatal().Err(err).Msg("Failed to run database migration")
	}
	log.Info().Msg("✅ Database migration applied successfully")
}
