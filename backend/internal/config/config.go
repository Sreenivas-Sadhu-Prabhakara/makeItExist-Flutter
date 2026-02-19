package config

import (
	"os"
	"strconv"
	"time"

	"github.com/joho/godotenv"
	"github.com/rs/zerolog/log"
)

// Config holds all application configuration
type Config struct {
	Server   ServerConfig
	Database DatabaseConfig
	JWT      JWTConfig
	OTP      OTPConfig
	SMTP     SMTPConfig
	AIM      AIMConfig
	Rate     RateConfig
	CORS     CORSConfig
}

type ServerConfig struct {
	Port         string
	Env          string
	ReadTimeout  time.Duration
	WriteTimeout time.Duration
}

type DatabaseConfig struct {
	Host                  string
	Port                  string
	User                  string
	Password              string
	Name                  string
	SSLMode               string
	MaxConnections        int
	MaxIdleConnections    int
	ConnectionMaxLifetime time.Duration
}

type JWTConfig struct {
	Secret       string
	Expiry       time.Duration
	RefreshExpiry time.Duration
}

type OTPConfig struct {
	ExpiryMinutes int
	Length        int
}

type SMTPConfig struct {
	Host     string
	Port     string
	User     string
	Password string
}

type AIMConfig struct {
	EmailDomain string
}

type RateConfig struct {
	RPS   int
	Burst int
}

type CORSConfig struct {
	AllowedOrigins string
}

// Load reads configuration from environment variables
func Load() *Config {
	// Load .env file if it exists (development)
	if err := godotenv.Load(); err != nil {
		log.Warn().Msg("No .env file found, using environment variables")
	}

	return &Config{
		Server: ServerConfig{
			Port:         getEnv("SERVER_PORT", "8080"),
			Env:          getEnv("SERVER_ENV", "development"),
			ReadTimeout:  getDurationEnv("SERVER_READ_TIMEOUT", 10*time.Second),
			WriteTimeout: getDurationEnv("SERVER_WRITE_TIMEOUT", 10*time.Second),
		},
		Database: DatabaseConfig{
			Host:                  getEnv("DB_HOST", "localhost"),
			Port:                  getEnv("DB_PORT", "5432"),
			User:                  getEnv("DB_USER", "makeitexist"),
			Password:              getEnv("DB_PASSWORD", "changeme"),
			Name:                  getEnv("DB_NAME", "makeitexist"),
			SSLMode:               getEnv("DB_SSLMODE", "disable"),
			MaxConnections:        getIntEnv("DB_MAX_CONNECTIONS", 25),
			MaxIdleConnections:    getIntEnv("DB_MAX_IDLE_CONNECTIONS", 5),
			ConnectionMaxLifetime: getDurationEnv("DB_CONNECTION_MAX_LIFETIME", 5*time.Minute),
		},
		JWT: JWTConfig{
			Secret:       getEnv("JWT_SECRET", "default-dev-secret"),
			Expiry:       getDurationEnv("JWT_EXPIRY", 24*time.Hour),
			RefreshExpiry: getDurationEnv("JWT_REFRESH_EXPIRY", 168*time.Hour),
		},
		OTP: OTPConfig{
			ExpiryMinutes: getIntEnv("OTP_EXPIRY_MINUTES", 10),
			Length:        getIntEnv("OTP_LENGTH", 6),
		},
		SMTP: SMTPConfig{
			Host:     getEnv("SMTP_HOST", "smtp.gmail.com"),
			Port:     getEnv("SMTP_PORT", "587"),
			User:     getEnv("SMTP_USER", ""),
			Password: getEnv("SMTP_PASSWORD", ""),
		},
		AIM: AIMConfig{
			EmailDomain: getEnv("AIM_EMAIL_DOMAIN", "aim.edu"),
		},
		Rate: RateConfig{
			RPS:   getIntEnv("RATE_LIMIT_RPS", 10),
			Burst: getIntEnv("RATE_LIMIT_BURST", 20),
		},
		CORS: CORSConfig{
			AllowedOrigins: getEnv("CORS_ALLOWED_ORIGINS", "http://localhost:3000"),
		},
	}
}

// DSN returns the PostgreSQL connection string.
// If DATABASE_URL is set (e.g. on Render.com), it takes priority.
func (d *DatabaseConfig) DSN() string {
	if url, ok := os.LookupEnv("DATABASE_URL"); ok && url != "" {
		log.Info().Msg("Using DATABASE_URL from environment")
		return url
	}
	log.Warn().Str("host", d.Host).Str("port", d.Port).Str("user", d.User).Str("dbname", d.Name).
		Msg("DATABASE_URL not set, falling back to individual DB_* vars")
	return "host=" + d.Host +
		" port=" + d.Port +
		" user=" + d.User +
		" password=" + d.Password +
		" dbname=" + d.Name +
		" sslmode=" + d.SSLMode
}

func getEnv(key, fallback string) string {
	if val, ok := os.LookupEnv(key); ok {
		return val
	}
	return fallback
}

func getIntEnv(key string, fallback int) int {
	if val, ok := os.LookupEnv(key); ok {
		if i, err := strconv.Atoi(val); err == nil {
			return i
		}
	}
	return fallback
}

func getDurationEnv(key string, fallback time.Duration) time.Duration {
	if val, ok := os.LookupEnv(key); ok {
		if d, err := time.ParseDuration(val); err == nil {
			return d
		}
	}
	return fallback
}
