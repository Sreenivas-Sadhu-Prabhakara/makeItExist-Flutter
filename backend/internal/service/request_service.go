package service

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/makeitexist/backend/internal/domain"
)

type requestService struct {
	requestRepo domain.BuildRequestRepository
	userRepo    domain.UserRepository
}

// NewRequestService creates a new build request service
func NewRequestService(requestRepo domain.BuildRequestRepository, userRepo domain.UserRepository) domain.BuildRequestService {
	return &requestService{
		requestRepo: requestRepo,
		userRepo:    userRepo,
	}
}

func (s *requestService) Create(ctx context.Context, userID uuid.UUID, req *domain.CreateBuildRequest) (*domain.BuildRequest, error) {
	// Verify user exists
	user, err := s.userRepo.FindByID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to find user: %w", err)
	}
	if user == nil {
		return nil, errors.New("user not found")
	}

	// Determine if request is free or paid
	isFree := req.RequestType == domain.RequestTypeWebsite && req.HostingType != domain.HostingWhitelabel

	// Calculate estimated cost
	complexity := domain.ComplexityBasic // Default, admin can update
	estimatedCost := domain.CalculateCost(req.RequestType, complexity, req.HostingType)

	// All requests start as pending — pricing is discussed offline with the builder
	buildReq := &domain.BuildRequest{
		ID:                 uuid.New(),
		UserID:             userID,
		Title:              req.Title,
		Description:        req.Description,
		RequestType:        req.RequestType,
		Status:             domain.StatusPending,
		Complexity:         complexity,
		HostingType:        req.HostingType,
		WhitelabelDomain:   req.WhitelabelDomain,
		WhitelabelBranding: req.WhitelabelBranding,
		WhitelabelHosting:  req.WhitelabelHosting,
		TechRequirements:   req.TechRequirements,
		ReferenceLinks:     req.ReferenceLinks,
		Figma:              req.Figma,
		HostingEmail:       req.HostingEmail,
		EstimatedCost:      estimatedCost,
		IsFree:             isFree,
		CreatedAt:          time.Now(),
		UpdatedAt:          time.Now(),
	}

	if err := s.requestRepo.Create(ctx, buildReq); err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	return buildReq, nil
}

func (s *requestService) GetByID(ctx context.Context, id uuid.UUID) (*domain.BuildRequest, error) {
	req, err := s.requestRepo.FindByID(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("failed to find request: %w", err)
	}
	if req == nil {
		return nil, errors.New("request not found")
	}
	return req, nil
}

func (s *requestService) Update(ctx context.Context, id uuid.UUID, updateReq *domain.UpdateBuildRequest) (*domain.BuildRequest, error) {
	req, err := s.requestRepo.FindByID(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("failed to find request: %w", err)
	}
	if req == nil {
		return nil, errors.New("request not found")
	}

	// Apply updates
	if updateReq.Status != nil {
		req.Status = *updateReq.Status
	}
	if updateReq.Complexity != nil {
		req.Complexity = *updateReq.Complexity
		// Recalculate cost
		req.EstimatedCost = domain.CalculateCost(req.RequestType, req.Complexity, req.HostingType)
	}
	if updateReq.EstimatedCost != nil {
		req.EstimatedCost = *updateReq.EstimatedCost
	}
	if updateReq.ScheduledWeekend != nil {
		req.ScheduledWeekend = *updateReq.ScheduledWeekend
	}
	if updateReq.BuilderID != nil {
		req.BuilderID = updateReq.BuilderID
	}
	if updateReq.DeliveryURL != nil {
		req.DeliveryURL = *updateReq.DeliveryURL
	}
	if updateReq.RepoURL != nil {
		req.RepoURL = *updateReq.RepoURL
	}

	// If marking as completed, set completion time
	if updateReq.Status != nil && *updateReq.Status == domain.StatusCompleted {
		now := time.Now()
		req.CompletedAt = &now
	}

	req.UpdatedAt = time.Now()

	if err := s.requestRepo.Update(ctx, req); err != nil {
		return nil, fmt.Errorf("failed to update request: %w", err)
	}

	return req, nil
}

func (s *requestService) ListByUser(ctx context.Context, userID uuid.UUID, limit, offset int) ([]domain.BuildRequest, int, error) {
	filter := domain.RequestFilter{
		UserID: &userID,
		Limit:  limit,
		Offset: offset,
	}
	return s.requestRepo.List(ctx, filter)
}

func (s *requestService) ListAll(ctx context.Context, filter domain.RequestFilter) ([]domain.BuildRequest, int, error) {
	return s.requestRepo.List(ctx, filter)
}
