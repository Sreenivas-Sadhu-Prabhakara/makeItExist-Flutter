package repository

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/makeitexist/backend/internal/domain"
)

type scheduleRepo struct {
	db *pgxpool.Pool
}

// NewScheduleRepository creates a new schedule repository
func NewScheduleRepository(db *pgxpool.Pool) domain.ScheduleRepository {
	return &scheduleRepo{db: db}
}

func (r *scheduleRepo) CreateSlot(ctx context.Context, slot *domain.WeekendSlot) error {
	query := `
		INSERT INTO weekend_slots (id, date, day_of_week, total_hours, booked_hours, 
		       max_projects, booked_projects, status, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
	`
	_, err := r.db.Exec(ctx, query,
		slot.ID, slot.Date, slot.DayOfWeek, slot.TotalHours,
		slot.BookedHours, slot.MaxProjects, slot.BookedProjects,
		slot.Status, slot.CreatedAt,
	)
	return err
}

func (r *scheduleRepo) FindSlotByDate(ctx context.Context, date time.Time) (*domain.WeekendSlot, error) {
	query := `
		SELECT id, date, day_of_week, total_hours, booked_hours, 
		       max_projects, booked_projects, status, created_at
		FROM weekend_slots WHERE date = $1
	`
	slot := &domain.WeekendSlot{}
	err := r.db.QueryRow(ctx, query, date).Scan(
		&slot.ID, &slot.Date, &slot.DayOfWeek, &slot.TotalHours,
		&slot.BookedHours, &slot.MaxProjects, &slot.BookedProjects,
		&slot.Status, &slot.CreatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}
	return slot, nil
}

func (r *scheduleRepo) FindSlotByID(ctx context.Context, id uuid.UUID) (*domain.WeekendSlot, error) {
	query := `
		SELECT id, date, day_of_week, total_hours, booked_hours, 
		       max_projects, booked_projects, status, created_at
		FROM weekend_slots WHERE id = $1
	`
	slot := &domain.WeekendSlot{}
	err := r.db.QueryRow(ctx, query, id).Scan(
		&slot.ID, &slot.Date, &slot.DayOfWeek, &slot.TotalHours,
		&slot.BookedHours, &slot.MaxProjects, &slot.BookedProjects,
		&slot.Status, &slot.CreatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}
	return slot, nil
}

func (r *scheduleRepo) UpdateSlot(ctx context.Context, slot *domain.WeekendSlot) error {
	query := `
		UPDATE weekend_slots SET booked_hours=$1, booked_projects=$2, status=$3
		WHERE id=$4
	`
	_, err := r.db.Exec(ctx, query, slot.BookedHours, slot.BookedProjects, slot.Status, slot.ID)
	return err
}

func (r *scheduleRepo) ListUpcomingSlots(ctx context.Context, limit int) ([]domain.WeekendSlot, error) {
	query := `
		SELECT id, date, day_of_week, total_hours, booked_hours, 
		       max_projects, booked_projects, status, created_at
		FROM weekend_slots
		WHERE date >= CURRENT_DATE
		ORDER BY date ASC
		LIMIT $1
	`
	rows, err := r.db.Query(ctx, query, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var slots []domain.WeekendSlot
	for rows.Next() {
		var s domain.WeekendSlot
		if err := rows.Scan(
			&s.ID, &s.Date, &s.DayOfWeek, &s.TotalHours,
			&s.BookedHours, &s.MaxProjects, &s.BookedProjects,
			&s.Status, &s.CreatedAt,
		); err != nil {
			return nil, err
		}
		slots = append(slots, s)
	}
	return slots, nil
}

func (r *scheduleRepo) CreateEntry(ctx context.Context, entry *domain.ScheduleEntry) error {
	query := `
		INSERT INTO schedule_entries (id, request_id, slot_id, builder_id, estimated_hours, 
		       status, notes, start_time, end_time, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
	`
	_, err := r.db.Exec(ctx, query,
		entry.ID, entry.RequestID, entry.SlotID, entry.BuilderID,
		entry.Hours, entry.Status, entry.Notes,
		entry.StartTime, entry.EndTime, entry.CreatedAt, entry.UpdatedAt,
	)
	return err
}

func (r *scheduleRepo) FindEntriesBySlot(ctx context.Context, slotID uuid.UUID) ([]domain.ScheduleEntry, error) {
	query := `
		SELECT id, request_id, slot_id, builder_id, estimated_hours, 
		       status, notes, start_time, end_time, created_at, updated_at
		FROM schedule_entries WHERE slot_id = $1
		ORDER BY start_time ASC
	`
	rows, err := r.db.Query(ctx, query, slotID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var entries []domain.ScheduleEntry
	for rows.Next() {
		var e domain.ScheduleEntry
		if err := rows.Scan(
			&e.ID, &e.RequestID, &e.SlotID, &e.BuilderID,
			&e.Hours, &e.Status, &e.Notes,
			&e.StartTime, &e.EndTime, &e.CreatedAt, &e.UpdatedAt,
		); err != nil {
			return nil, err
		}
		entries = append(entries, e)
	}
	return entries, nil
}

func (r *scheduleRepo) FindEntriesByRequest(ctx context.Context, requestID uuid.UUID) ([]domain.ScheduleEntry, error) {
	query := `
		SELECT id, request_id, slot_id, builder_id, estimated_hours, 
		       status, notes, start_time, end_time, created_at, updated_at
		FROM schedule_entries WHERE request_id = $1
	`
	rows, err := r.db.Query(ctx, query, requestID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var entries []domain.ScheduleEntry
	for rows.Next() {
		var e domain.ScheduleEntry
		if err := rows.Scan(
			&e.ID, &e.RequestID, &e.SlotID, &e.BuilderID,
			&e.Hours, &e.Status, &e.Notes,
			&e.StartTime, &e.EndTime, &e.CreatedAt, &e.UpdatedAt,
		); err != nil {
			return nil, err
		}
		entries = append(entries, e)
	}
	return entries, nil
}

func (r *scheduleRepo) UpdateEntry(ctx context.Context, entry *domain.ScheduleEntry) error {
	query := `
		UPDATE schedule_entries SET builder_id=$1, status=$2, notes=$3, updated_at=$4
		WHERE id=$5
	`
	_, err := r.db.Exec(ctx, query, entry.BuilderID, entry.Status, entry.Notes, time.Now(), entry.ID)
	return err
}
