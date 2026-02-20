package router

import (
	"mime"
	"net/http"
	"os"
	"path"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/makeitexist/backend/internal/config"
	"github.com/makeitexist/backend/internal/handler"
	"github.com/makeitexist/backend/internal/middleware"
)

// Setup configures all routes for the application
func Setup(
	cfg *config.Config,
	authHandler *handler.AuthHandler,
	requestHandler *handler.RequestHandler,
	scheduleHandler *handler.ScheduleHandler,
	adminHandler *handler.AdminHandler,
) *gin.Engine {
	// Set Gin mode based on environment
	if cfg.Server.Env == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	r := gin.New()

	// Global middleware
	r.Use(gin.Recovery())
	r.Use(middleware.LoggingMiddleware())
	r.Use(middleware.CORSMiddleware(cfg))
	r.Use(middleware.RateLimitMiddleware(cfg))

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "healthy",
			"service": "make-it-exist-api",
			"version": "1.0.0",
		})
	})

	// API v1 routes
	v1 := r.Group("/api/v1")

	// === Public Routes (No Auth) ===
	auth := v1.Group("/auth")
	{
		auth.POST("/google", authHandler.GoogleLogin)
		auth.POST("/firebase", authHandler.FirebaseLogin) // Google, Facebook, Microsoft
		auth.POST("/login", authHandler.Login)            // admin password fallback
	}

	// === Protected Routes (Auth Required) ===
	protected := v1.Group("")
	protected.Use(middleware.AuthMiddleware(cfg))
	{
		// Profile
		protected.GET("/auth/profile", authHandler.GetProfile)

		// Build Requests
		requests := protected.Group("/requests")
		{
			requests.POST("", requestHandler.Create)
			requests.GET("", requestHandler.ListMyRequests)
			requests.GET("/:id", requestHandler.GetByID)
		}

		// Schedule
		schedule := protected.Group("/schedule")
		{
			schedule.GET("", scheduleHandler.GetScheduleForWeekend)
			schedule.GET("/slots", scheduleHandler.GetUpcomingSlots)
		}

	}

	// === Admin Routes (Admin Auth Required) ===
	admin := v1.Group("/admin")
	admin.Use(middleware.AuthMiddleware(cfg))
	admin.Use(middleware.AdminOnly())
	{
		admin.GET("/dashboard", adminHandler.Dashboard)
		admin.GET("/requests", requestHandler.ListAll)
		admin.PUT("/requests/:id", requestHandler.Update)
		admin.POST("/schedule/generate", scheduleHandler.GenerateSlots)
		admin.GET("/users", adminHandler.ListUsers)
		admin.PUT("/users/:id/reset-password", adminHandler.ResetPassword)
		admin.POST("/create-admin", adminHandler.CreateOrUpdateAdmin)
	}

	// ── Serve Flutter Web Frontend (SPA) ─────────────────────────
	// Resolve the static directory from env or default
	webDir := os.Getenv("FRONTEND_DIR")
	if webDir == "" {
		webDir = "../frontend/build/web" // default for local dev
	}

	// Register WASM/JS MIME types
	mime.AddExtensionType(".wasm", "application/wasm")
	mime.AddExtensionType(".js", "text/javascript")

	// Serve static files and SPA fallback at /
	r.Use(serveSPA(webDir))

	return r
}

// serveSPA returns middleware that serves static files from webDir.
// For any path that doesn't match a real file AND doesn't start with /api/,
// it serves index.html (SPA client-side routing fallback).
func serveSPA(webDir string) gin.HandlerFunc {
	fileServer := http.FileServer(http.Dir(webDir))

	return func(c *gin.Context) {
		urlPath := c.Request.URL.Path

		// Never intercept API or health routes
		if strings.HasPrefix(urlPath, "/api/") || urlPath == "/health" {
			c.Next()
			return
		}

		// Check if the requested file exists on disk
		filePath := path.Join(webDir, path.Clean(urlPath))
		info, err := os.Stat(filePath)
		if err != nil || info.IsDir() {
			// File not found or is a directory → serve index.html (SPA fallback)
			c.Header("Cross-Origin-Embedder-Policy", "credentialless")
			c.Header("Cross-Origin-Opener-Policy", "same-origin-allow-popups")
			c.File(path.Join(webDir, "index.html"))
			c.Abort()
			return
		}

		// Serve the actual static file with COOP/COEP headers
		c.Header("Cross-Origin-Embedder-Policy", "credentialless")
		c.Header("Cross-Origin-Opener-Policy", "same-origin-allow-popups")
		fileServer.ServeHTTP(c.Writer, c.Request)
		c.Abort()
	}
}
