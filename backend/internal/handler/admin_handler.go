package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/makeitexist/backend/internal/domain"
)

// AdminHandler handles admin dashboard endpoints
type AdminHandler struct {
	requestService  domain.BuildRequestService
	scheduleService domain.ScheduleService
}

// NewAdminHandler creates a new admin handler
func NewAdminHandler(requestService domain.BuildRequestService, scheduleService domain.ScheduleService) *AdminHandler {
	return &AdminHandler{
		requestService:  requestService,
		scheduleService: scheduleService,
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
