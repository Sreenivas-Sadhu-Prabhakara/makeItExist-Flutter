package domain

import (
	"context"
	"time"

	"github.com/google/uuid"
)

// RequestType defines what the student wants built
type RequestType string

const (
	RequestTypeWebsite   RequestType = "website"
	RequestTypeMobileApp RequestType = "mobile_app"
	RequestTypeBoth      RequestType = "both"
)

// RequestStatus tracks the lifecycle of a build request
type RequestStatus string

const (
	StatusPending    RequestStatus = "pending"
	StatusQueued     RequestStatus = "queued"
	StatusScheduled  RequestStatus = "scheduled"
	StatusBuilding   RequestStatus = "building"
	StatusReview     RequestStatus = "review"
	StatusDeploying  RequestStatus = "deploying"
	StatusCompleted  RequestStatus = "completed"
	StatusCancelled  RequestStatus = "cancelled"
	StatusRejected   RequestStatus = "rejected"
)

// HostingType defines where the project will be deployed
type HostingType string

const (
	HostingFreeVercel  HostingType = "vercel"
	HostingFreeReplit  HostingType = "replit"
	HostingFreeHeroku  HostingType = "heroku"
	HostingWhitelabel  HostingType = "whitelabel"
)

// ComplexityLevel determines pricing for paid services
type ComplexityLevel string

const (
	ComplexityBasic    ComplexityLevel = "basic"
	ComplexityStandard ComplexityLevel = "standard"
	ComplexityAdvanced ComplexityLevel = "advanced"
)

// BuildRequest represents a student's project request
type BuildRequest struct {
	ID              uuid.UUID       `json:"id"`
	UserID          uuid.UUID       `json:"user_id"`
	Title           string          `json:"title"`
	Description     string          `json:"description"`
	RequestType     RequestType     `json:"request_type"`
	Status          RequestStatus   `json:"status"`
	Complexity      ComplexityLevel `json:"complexity"`
	HostingType     HostingType     `json:"hosting_type"`
	
	// Whitelabel-specific fields
	WhitelabelDomain   string `json:"whitelabel_domain,omitempty"`
	WhitelabelBranding string `json:"whitelabel_branding,omitempty"`
	WhitelabelHosting  string `json:"whitelabel_hosting_platform,omitempty"`
	
	// Technical details
	TechRequirements string `json:"tech_requirements,omitempty"`
	ReferenceLinks   string `json:"reference_links,omitempty"`
	Figma            string `json:"figma_link,omitempty"`
	
	// Hosting details (student's accounts)
	HostingEmail     string `json:"hosting_email,omitempty"`
	
	// Pricing
	EstimatedCost    float64 `json:"estimated_cost"`
	IsFree           bool    `json:"is_free"`
	
	// Delivery
	DeliveryURL      string    `json:"delivery_url,omitempty"`
	RepoURL          string    `json:"repo_url,omitempty"`
	
	// Scheduling
	ScheduledWeekend time.Time `json:"scheduled_weekend,omitempty"`
	BuilderID        *uuid.UUID `json:"builder_id,omitempty"`
	
	// Timestamps
	CreatedAt        time.Time `json:"created_at"`
	UpdatedAt        time.Time `json:"updated_at"`
	CompletedAt      *time.Time `json:"completed_at,omitempty"`
}

// CreateBuildRequest is the input for creating a new request
type CreateBuildRequest struct {
	Title             string      `json:"title" binding:"required"`
	Description       string      `json:"description" binding:"required"`
	RequestType       RequestType `json:"request_type" binding:"required,oneof=website mobile_app both"`
	HostingType       HostingType `json:"hosting_type" binding:"required"`
	TechRequirements  string      `json:"tech_requirements"`
	ReferenceLinks    string      `json:"reference_links"`
	Figma             string      `json:"figma_link"`
	HostingEmail      string      `json:"hosting_email"`
	WhitelabelDomain  string      `json:"whitelabel_domain"`
	WhitelabelBranding string     `json:"whitelabel_branding"`
	WhitelabelHosting string      `json:"whitelabel_hosting_platform"`
}

// UpdateBuildRequest is the input for updating a request (admin)
type UpdateBuildRequest struct {
	Status          *RequestStatus  `json:"status"`
	Complexity      *ComplexityLevel `json:"complexity"`
	EstimatedCost   *float64        `json:"estimated_cost"`
	ScheduledWeekend *time.Time     `json:"scheduled_weekend"`
	BuilderID       *uuid.UUID      `json:"builder_id"`
	DeliveryURL     *string         `json:"delivery_url"`
	RepoURL         *string         `json:"repo_url"`
}

// RequestFilter for listing/searching requests
type RequestFilter struct {
	UserID      *uuid.UUID
	Status      *RequestStatus
	RequestType *RequestType
	Limit       int
	Offset      int
}

// IsPaidRequest checks if a request type is typically charged (pricing discussed offline with builder)
func (r *BuildRequest) IsPaidRequest() bool {
	// Websites are always free
	if r.RequestType == RequestTypeWebsite && r.HostingType != HostingWhitelabel {
		return false
	}
	// Everything else is paid
	return true
}

// CalculateCost estimates the cost based on type and complexity
func CalculateCost(reqType RequestType, complexity ComplexityLevel, hosting HostingType) float64 {
	if reqType == RequestTypeWebsite && hosting != HostingWhitelabel {
		return 0.0
	}

	baseCost := map[ComplexityLevel]float64{
		ComplexityBasic:    2999.0,  // ₹2,999
		ComplexityStandard: 5999.0,  // ₹5,999
		ComplexityAdvanced: 11999.0, // ₹11,999
	}

	cost := baseCost[complexity]

	// Mobile app premium
	if reqType == RequestTypeMobileApp || reqType == RequestTypeBoth {
		cost *= 1.5
	}

	// Whitelabel premium
	if hosting == HostingWhitelabel {
		cost += 1999.0
	}

	return cost
}

// BuildRequestRepository defines the interface for request data access
type BuildRequestRepository interface {
	Create(ctx context.Context, req *BuildRequest) error
	FindByID(ctx context.Context, id uuid.UUID) (*BuildRequest, error)
	Update(ctx context.Context, req *BuildRequest) error
	List(ctx context.Context, filter RequestFilter) ([]BuildRequest, int, error)
	CountByStatus(ctx context.Context, status RequestStatus) (int, error)
	GetWeekendRequests(ctx context.Context, weekendStart time.Time) ([]BuildRequest, error)
}

// BuildRequestService defines the interface for request business logic
type BuildRequestService interface {
	Create(ctx context.Context, userID uuid.UUID, req *CreateBuildRequest) (*BuildRequest, error)
	GetByID(ctx context.Context, id uuid.UUID) (*BuildRequest, error)
	Update(ctx context.Context, id uuid.UUID, req *UpdateBuildRequest) (*BuildRequest, error)
	ListByUser(ctx context.Context, userID uuid.UUID, limit, offset int) ([]BuildRequest, int, error)
	ListAll(ctx context.Context, filter RequestFilter) ([]BuildRequest, int, error)
}
