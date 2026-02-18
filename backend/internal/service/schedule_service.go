package service

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/makeitexist/backend/internal/domain"
)

type scheduleService struct {
	scheduleRepo domain.ScheduleRepository
	requestRepo  domain.BuildRequestRepository
}

// NewScheduleService creates a new schedule service
func NewScheduleService(scheduleRepo domain.ScheduleRepository, requestRepo domain.BuildRequestRepository) domain.ScheduleService {
	return &scheduleService{
		scheduleRepo: scheduleRepo,
		requestRepo:  requestRepo,
	}
}

func (s *scheduleService) GetUpcomingSlots(ctx context.Context) ([]domain.WeekendSlot, error) {
	return s.scheduleRepo.ListUpcomingSlots(ctx, 20) // Next 10 weekends
}

func (s *scheduleService) GetScheduleForWeekend(ctx context.Context, date time.Time) (*domain.ScheduleView, error) {
	slot, err := s.scheduleRepo.FindSlotByDate(ctx, date)
	if err != nil {
		return nil, fmt.Errorf("failed to find slot: %w", err)
	}
	if slot == nil {
		return nil, errors.New("no slot found for this date")
	}

	entries, err := s.scheduleRepo.FindEntriesBySlot(ctx, slot.ID)
	if err != nil {
		return nil, fmt.Errorf("failed to find entries: %w", err)
	}

	// Load associated requests
	var requests []domain.BuildRequest
	for _, entry := range entries {
		req, err := s.requestRepo.FindByID(ctx, entry.RequestID)
		if err != nil {
			continue
		}
		if req != nil {
			requests = append(requests, *req)
		}
	}

	return &domain.ScheduleView{
		Slot:     *slot,
		Entries:  entries,
		Requests: requests,
	}, nil
}

func (s *scheduleService) ScheduleRequest(ctx context.Context, requestID uuid.UUID, slotID uuid.UUID, hours int) (*domain.ScheduleEntry, error) {
	// Verify slot exists and has capacity
	slot, err := s.scheduleRepo.FindSlotByID(ctx, slotID)
	if err != nil {
		return nil, fmt.Errorf("failed to find slot: %w", err)
	}
	if slot == nil {
		return nil, errors.New("slot not found")
	}
	if slot.Status == domain.SlotFull {
		return nil, errors.New("slot is full")
	}
	if slot.BookedHours+hours > slot.TotalHours {
		return nil, errors.New("not enough hours available in this slot")
	}

	// Verify request exists
	req, err := s.requestRepo.FindByID(ctx, requestID)
	if err != nil {
		return nil, fmt.Errorf("failed to find request: %w", err)
	}
	if req == nil {
		return nil, errors.New("request not found")
	}

	// Create schedule entry
	now := time.Now()
	entry := &domain.ScheduleEntry{
		ID:        uuid.New(),
		RequestID: requestID,
		SlotID:    slotID,
		Hours:     hours,
		Status:    domain.StatusScheduled,
		StartTime: slot.Date,
		EndTime:   slot.Date.Add(time.Duration(hours) * time.Hour),
		CreatedAt: now,
		UpdatedAt: now,
	}

	if err := s.scheduleRepo.CreateEntry(ctx, entry); err != nil {
		return nil, fmt.Errorf("failed to create entry: %w", err)
	}

	// Update slot booked hours
	slot.BookedHours += hours
	slot.BookedProjects++
	if slot.BookedProjects >= slot.MaxProjects || slot.BookedHours >= slot.TotalHours {
		slot.Status = domain.SlotFull
	} else {
		slot.Status = domain.SlotBooked
	}
	if err := s.scheduleRepo.UpdateSlot(ctx, slot); err != nil {
		return nil, fmt.Errorf("failed to update slot: %w", err)
	}

	// Update request status to scheduled
	req.Status = domain.StatusScheduled
	req.ScheduledWeekend = slot.Date
	if err := s.requestRepo.Update(ctx, req); err != nil {
		return nil, fmt.Errorf("failed to update request: %w", err)
	}

	return entry, nil
}

func (s *scheduleService) AutoGenerateWeekendSlots(ctx context.Context, weeksAhead int) error {
	now := time.Now()

	for i := 0; i < weeksAhead; i++ {
		// Find next Saturday
		daysUntilSat := (6 - int(now.Weekday()) + 7) % 7
		if daysUntilSat == 0 && i == 0 {
			daysUntilSat = 7
		}
		saturday := now.AddDate(0, 0, daysUntilSat+(i*7))
		saturday = time.Date(saturday.Year(), saturday.Month(), saturday.Day(), 0, 0, 0, 0, now.Location())
		sunday := saturday.AddDate(0, 0, 1)

		// Create Saturday slot
		satSlot, _ := s.scheduleRepo.FindSlotByDate(ctx, saturday)
		if satSlot == nil {
			satSlot = &domain.WeekendSlot{
				ID:          uuid.New(),
				Date:        saturday,
				DayOfWeek:   "saturday",
				TotalHours:  8,
				MaxProjects: 5,
				Status:      domain.SlotAvailable,
				CreatedAt:   time.Now(),
			}
			if err := s.scheduleRepo.CreateSlot(ctx, satSlot); err != nil {
				return fmt.Errorf("failed to create Saturday slot: %w", err)
			}
		}

		// Create Sunday slot
		sunSlot, _ := s.scheduleRepo.FindSlotByDate(ctx, sunday)
		if sunSlot == nil {
			sunSlot = &domain.WeekendSlot{
				ID:          uuid.New(),
				Date:        sunday,
				DayOfWeek:   "sunday",
				TotalHours:  8,
				MaxProjects: 5,
				Status:      domain.SlotAvailable,
				CreatedAt:   time.Now(),
			}
			if err := s.scheduleRepo.CreateSlot(ctx, sunSlot); err != nil {
				return fmt.Errorf("failed to create Sunday slot: %w", err)
			}
		}
	}

	return nil
}
