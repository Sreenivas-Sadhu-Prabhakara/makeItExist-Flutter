package handler

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/makeitexist/backend/internal/domain"
)

// ScheduleHandler handles schedule endpoints
type ScheduleHandler struct {
	scheduleService domain.ScheduleService
}

// NewScheduleHandler creates a new schedule handler
func NewScheduleHandler(scheduleService domain.ScheduleService) *ScheduleHandler {
	return &ScheduleHandler{scheduleService: scheduleService}
}

// GetUpcomingSlots returns available weekend build slots
// GET /api/v1/schedule/slots
func (h *ScheduleHandler) GetUpcomingSlots(c *gin.Context) {
	slots, err := h.scheduleService.GetUpcomingSlots(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "fetch_failed",
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data":    slots,
		"message": "Weekend build slots (Saturday & Sunday, 8 hours each)",
	})
}

// GetScheduleForWeekend returns the full schedule for a specific weekend
// GET /api/v1/schedule?date=2026-02-21
func (h *ScheduleHandler) GetScheduleForWeekend(c *gin.Context) {
	dateStr := c.Query("date")
	if dateStr == "" {
		// Default to next Saturday
		date := domain.NextWeekendSaturday()
		dateStr = date.Format("2006-01-02")
	}

	date, err := time.Parse("2006-01-02", dateStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_date",
			"message": "Date must be in YYYY-MM-DD format",
		})
		return
	}

	view, err := h.scheduleService.GetScheduleForWeekend(c.Request.Context(), date)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"error":   "not_found",
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{"data": view})
}

// GenerateSlots auto-generates weekend slots (admin only)
// POST /api/v1/admin/schedule/generate
func (h *ScheduleHandler) GenerateSlots(c *gin.Context) {
	if err := h.scheduleService.AutoGenerateWeekendSlots(c.Request.Context(), 8); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "generation_failed",
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Weekend slots generated for the next 8 weeks",
	})
}
