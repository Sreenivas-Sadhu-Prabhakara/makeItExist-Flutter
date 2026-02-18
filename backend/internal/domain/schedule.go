package domain

import (
	"context"
	"time"

	"github.com/google/uuid"
)

// SlotStatus represents availability of a weekend slot
type SlotStatus string

const (
	SlotAvailable SlotStatus = "available"
	SlotBooked    SlotStatus = "booked"
	SlotFull      SlotStatus = "full"
)

// WeekendSlot represents a build slot on a weekend day
type WeekendSlot struct {
	ID            uuid.UUID  `json:"id"`
	Date          time.Time  `json:"date"`
	DayOfWeek     string     `json:"day_of_week"` // "saturday" or "sunday"
	TotalHours    int        `json:"total_hours"`  // 8
	BookedHours   int        `json:"booked_hours"`
	MaxProjects   int        `json:"max_projects"`
	BookedProjects int       `json:"booked_projects"`
	Status        SlotStatus `json:"status"`
	CreatedAt     time.Time  `json:"created_at"`
}

// ScheduleEntry links a build request to a weekend slot
type ScheduleEntry struct {
	ID          uuid.UUID     `json:"id"`
	RequestID   uuid.UUID     `json:"request_id"`
	SlotID      uuid.UUID     `json:"slot_id"`
	BuilderID   *uuid.UUID    `json:"builder_id,omitempty"`
	Hours       int           `json:"estimated_hours"`
	Status      RequestStatus `json:"status"`
	Notes       string        `json:"notes,omitempty"`
	StartTime   time.Time     `json:"start_time"`
	EndTime     time.Time     `json:"end_time"`
	CreatedAt   time.Time     `json:"created_at"`
	UpdatedAt   time.Time     `json:"updated_at"`
}

// ScheduleView is the combined view for the frontend
type ScheduleView struct {
	Slot     WeekendSlot     `json:"slot"`
	Entries  []ScheduleEntry `json:"entries"`
	Requests []BuildRequest  `json:"requests"`
}

// CreateSlotRequest is used to create weekend slots
type CreateSlotRequest struct {
	Date        time.Time `json:"date" binding:"required"`
	MaxProjects int       `json:"max_projects" binding:"required,min=1"`
}

// ScheduleRepository defines the interface for schedule data access
type ScheduleRepository interface {
	CreateSlot(ctx context.Context, slot *WeekendSlot) error
	FindSlotByDate(ctx context.Context, date time.Time) (*WeekendSlot, error)
	FindSlotByID(ctx context.Context, id uuid.UUID) (*WeekendSlot, error)
	UpdateSlot(ctx context.Context, slot *WeekendSlot) error
	ListUpcomingSlots(ctx context.Context, limit int) ([]WeekendSlot, error)
	
	CreateEntry(ctx context.Context, entry *ScheduleEntry) error
	FindEntriesBySlot(ctx context.Context, slotID uuid.UUID) ([]ScheduleEntry, error)
	FindEntriesByRequest(ctx context.Context, requestID uuid.UUID) ([]ScheduleEntry, error)
	UpdateEntry(ctx context.Context, entry *ScheduleEntry) error
}

// ScheduleService defines the interface for schedule business logic
type ScheduleService interface {
	GetUpcomingSlots(ctx context.Context) ([]WeekendSlot, error)
	GetScheduleForWeekend(ctx context.Context, date time.Time) (*ScheduleView, error)
	ScheduleRequest(ctx context.Context, requestID uuid.UUID, slotID uuid.UUID, hours int) (*ScheduleEntry, error)
	AutoGenerateWeekendSlots(ctx context.Context, weeksAhead int) error
}

// NextWeekendSaturday returns the next Saturday date
func NextWeekendSaturday() time.Time {
	now := time.Now()
	daysUntilSaturday := (6 - int(now.Weekday()) + 7) % 7
	if daysUntilSaturday == 0 {
		daysUntilSaturday = 7
	}
	saturday := now.AddDate(0, 0, daysUntilSaturday)
	return time.Date(saturday.Year(), saturday.Month(), saturday.Day(), 0, 0, 0, 0, now.Location())
}
