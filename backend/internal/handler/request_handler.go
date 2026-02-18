package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/makeitexist/backend/internal/domain"
)

// RequestHandler handles build request endpoints
type RequestHandler struct {
	requestService domain.BuildRequestService
}

// NewRequestHandler creates a new request handler
func NewRequestHandler(requestService domain.BuildRequestService) *RequestHandler {
	return &RequestHandler{requestService: requestService}
}

// Create handles creating a new build request
// POST /api/v1/requests
func (h *RequestHandler) Create(c *gin.Context) {
	userID := getUserIDFromContext(c)
	if userID == uuid.Nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	var req domain.CreateBuildRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "validation_error",
			"message": err.Error(),
		})
		return
	}

	buildReq, err := h.requestService.Create(c.Request.Context(), userID, &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "create_failed",
			"message": err.Error(),
		})
		return
	}

	// Build response message
	message := "Request submitted successfully! A builder will review it and contact you."
	if buildReq.IsFree {
		message = "🎉 Free website request submitted! It will be queued for the next available weekend build."
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": message,
		"data":    buildReq,
	})
}

// GetByID returns a specific build request
// GET /api/v1/requests/:id
func (h *RequestHandler) GetByID(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request ID"})
		return
	}

	req, err := h.requestService.GetByID(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"error":   "not_found",
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{"data": req})
}

// ListMyRequests returns the authenticated user's requests
// GET /api/v1/requests
func (h *RequestHandler) ListMyRequests(c *gin.Context) {
	userID := getUserIDFromContext(c)
	if userID == uuid.Nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	requests, total, err := h.requestService.ListByUser(c.Request.Context(), userID, limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "list_failed",
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data":   requests,
		"total":  total,
		"limit":  limit,
		"offset": offset,
	})
}

// Update handles updating a build request (admin only)
// PUT /api/v1/requests/:id
func (h *RequestHandler) Update(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request ID"})
		return
	}

	var req domain.UpdateBuildRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "validation_error",
			"message": err.Error(),
		})
		return
	}

	updated, err := h.requestService.Update(c.Request.Context(), id, &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "update_failed",
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Request updated",
		"data":    updated,
	})
}

// ListAll returns all requests (admin only)
// GET /api/v1/admin/requests
func (h *RequestHandler) ListAll(c *gin.Context) {
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "50"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	filter := domain.RequestFilter{
		Limit:  limit,
		Offset: offset,
	}

	// Optional status filter
	if statusStr := c.Query("status"); statusStr != "" {
		status := domain.RequestStatus(statusStr)
		filter.Status = &status
	}

	// Optional type filter
	if typeStr := c.Query("type"); typeStr != "" {
		reqType := domain.RequestType(typeStr)
		filter.RequestType = &reqType
	}

	requests, total, err := h.requestService.ListAll(c.Request.Context(), filter)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "list_failed",
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data":   requests,
		"total":  total,
		"limit":  limit,
		"offset": offset,
	})
}

// Helper to extract user ID from gin context
func getUserIDFromContext(c *gin.Context) uuid.UUID {
	userIDStr, exists := c.Get("userID")
	if !exists {
		return uuid.Nil
	}
	id, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		return uuid.Nil
	}
	return id
}
