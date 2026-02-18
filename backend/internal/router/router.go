package router

import (
	"net/http"

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
		auth.POST("/register", authHandler.Register)
		auth.POST("/login", authHandler.Login)
		auth.POST("/verify-otp", authHandler.VerifyOTP)
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
	}

	return r
}
