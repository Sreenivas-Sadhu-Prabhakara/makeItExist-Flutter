package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/makeitexist/backend/internal/domain"
)

// AdminHandler handles admin dashboard endpoints
type AdminHandler struct {
	requestService  domain.BuildRequestService
	scheduleService domain.ScheduleService
	authService     domain.UserService
}

// NewAdminHandler creates a new admin handler
func NewAdminHandler(requestService domain.BuildRequestService, scheduleService domain.ScheduleService, authService domain.UserService) *AdminHandler {
	return &AdminHandler{
		requestService:  requestService,
		scheduleService: scheduleService,
		authService:     authService,
	}
}

// Dashboard returns admin dashboard statistics
// GET /api/v1/admin/dashboard
func (h *AdminHandler) Dashboard(c *gin.Context) {
	ctx := c.Request.Context()

	// Get counts for each status
	statuses := []domain.RequestStatus{
		domain.StatusPending,
		domain.StatusQueued,
		domain.StatusScheduled,
		domain.StatusBuilding,
		domain.StatusCompleted,
	}

	stats := make(map[string]interface{})
	for _, status := range statuses {
		filter := domain.RequestFilter{
			Status: &status,
			Limit:  1,
			Offset: 0,
		}
		_, total, err := h.requestService.ListAll(ctx, filter)
		if err != nil {
			continue
		}
		stats[string(status)] = total
	}

	// Get upcoming slots
	slots, _ := h.scheduleService.GetUpcomingSlots(ctx)

	c.JSON(http.StatusOK, gin.H{
		"data": gin.H{
			"request_stats":  stats,
			"upcoming_slots": slots,
			"build_hours":    "8 hours per day (Sat + Sun)",
		},
	})
}

// ListUsers returns all users (admin only)
// GET /api/v1/admin/users
func (h *AdminHandler) ListUsers(c *gin.Context) {
	users, total, err := h.authService.ListUsers(c.Request.Context(), 200, 0)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "list_users_failed",
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data":  users,
		"total": total,
	})
}

// ResetPassword resets a user's password (admin only)
// PUT /api/v1/admin/users/:id/reset-password
func (h *AdminHandler) ResetPassword(c *gin.Context) {
	userID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_id",
			"message": "Invalid user ID",
		})
		return
	}

	var req struct {
		NewPassword string `json:"new_password" binding:"required,min=4"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "validation_error",
			"message": err.Error(),
		})
		return
	}

	if err := h.authService.AdminResetPassword(c.Request.Context(), userID, req.NewPassword); err != nil {
		status := http.StatusInternalServerError
		if err.Error() == "user not found" {
			status = http.StatusNotFound
		}
		c.JSON(status, gin.H{
			"error":   "reset_failed",
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Password reset successfully",
	})
}
