package repository

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/makeitexist/backend/internal/domain"
)

type requestRepo struct {
	db *pgxpool.Pool
}

// NewBuildRequestRepository creates a new build request repository
func NewBuildRequestRepository(db *pgxpool.Pool) domain.BuildRequestRepository {
	return &requestRepo{db: db}
}

func (r *requestRepo) Create(ctx context.Context, req *domain.BuildRequest) error {
	query := `
		INSERT INTO build_requests (
			id, user_id, title, description, request_type, status, complexity,
			hosting_type, whitelabel_domain, whitelabel_branding, whitelabel_hosting_platform,
			tech_requirements, reference_links, figma_link, hosting_email,
			estimated_cost, is_free, created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19
		)
	`
	_, err := r.db.Exec(ctx, query,
		req.ID, req.UserID, req.Title, req.Description,
		req.RequestType, req.Status, req.Complexity,
		req.HostingType, req.WhitelabelDomain, req.WhitelabelBranding,
		req.WhitelabelHosting, req.TechRequirements, req.ReferenceLinks,
		req.Figma, req.HostingEmail, req.EstimatedCost, req.IsFree,
		req.CreatedAt, req.UpdatedAt,
	)
	return err
}

func (r *requestRepo) FindByID(ctx context.Context, id uuid.UUID) (*domain.BuildRequest, error) {
	query := `
		SELECT id, user_id, title, description, request_type, status, complexity,
		       hosting_type, whitelabel_domain, whitelabel_branding, whitelabel_hosting_platform,
		       tech_requirements, reference_links, figma_link, hosting_email,
		       estimated_cost, is_free, delivery_url, repo_url,
		       scheduled_weekend, builder_id, created_at, updated_at, completed_at
		FROM build_requests WHERE id = $1
	`
	req := &domain.BuildRequest{}
	err := r.db.QueryRow(ctx, query, id).Scan(
		&req.ID, &req.UserID, &req.Title, &req.Description,
		&req.RequestType, &req.Status, &req.Complexity,
		&req.HostingType, &req.WhitelabelDomain, &req.WhitelabelBranding,
		&req.WhitelabelHosting, &req.TechRequirements, &req.ReferenceLinks,
		&req.Figma, &req.HostingEmail, &req.EstimatedCost, &req.IsFree,
		&req.DeliveryURL, &req.RepoURL, &req.ScheduledWeekend, &req.BuilderID,
		&req.CreatedAt, &req.UpdatedAt, &req.CompletedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}
	return req, nil
}

func (r *requestRepo) Update(ctx context.Context, req *domain.BuildRequest) error {
	query := `
		UPDATE build_requests SET
			status=$1, complexity=$2, estimated_cost=$3, is_free=$4,
			delivery_url=$5, repo_url=$6, scheduled_weekend=$7,
			builder_id=$8, updated_at=$9, completed_at=$10
		WHERE id=$11
	`
	_, err := r.db.Exec(ctx, query,
		req.Status, req.Complexity, req.EstimatedCost, req.IsFree,
		req.DeliveryURL, req.RepoURL, req.ScheduledWeekend,
		req.BuilderID, time.Now(), req.CompletedAt, req.ID,
	)
	return err
}

func (r *requestRepo) List(ctx context.Context, filter domain.RequestFilter) ([]domain.BuildRequest, int, error) {
	baseQuery := `FROM build_requests WHERE 1=1`
	args := []interface{}{}
	argIdx := 1

	if filter.UserID != nil {
		baseQuery += fmt.Sprintf(` AND user_id = $%d`, argIdx)
		args = append(args, *filter.UserID)
		argIdx++
	}
	if filter.Status != nil {
		baseQuery += fmt.Sprintf(` AND status = $%d`, argIdx)
		args = append(args, *filter.Status)
		argIdx++
	}
	if filter.RequestType != nil {
		baseQuery += fmt.Sprintf(` AND request_type = $%d`, argIdx)
		args = append(args, *filter.RequestType)
		argIdx++
	}

	// Count
	var total int
	countQuery := `SELECT COUNT(*) ` + baseQuery
	if err := r.db.QueryRow(ctx, countQuery, args...).Scan(&total); err != nil {
		return nil, 0, err
	}

	// Data with pagination
	dataQuery := fmt.Sprintf(`SELECT id, user_id, title, description, request_type, status, complexity,
		hosting_type, estimated_cost, is_free, delivery_url, created_at, updated_at %s ORDER BY created_at DESC LIMIT $%d OFFSET $%d`,
		baseQuery, argIdx, argIdx+1)
	args = append(args, filter.Limit, filter.Offset)

	rows, err := r.db.Query(ctx, dataQuery, args...)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var requests []domain.BuildRequest
	for rows.Next() {
		var req domain.BuildRequest
		if err := rows.Scan(
			&req.ID, &req.UserID, &req.Title, &req.Description,
			&req.RequestType, &req.Status, &req.Complexity,
			&req.HostingType, &req.EstimatedCost, &req.IsFree,
			&req.DeliveryURL, &req.CreatedAt, &req.UpdatedAt,
		); err != nil {
			return nil, 0, err
		}
		requests = append(requests, req)
	}
	return requests, total, nil
}

func (r *requestRepo) CountByStatus(ctx context.Context, status domain.RequestStatus) (int, error) {
	var count int
	err := r.db.QueryRow(ctx, `SELECT COUNT(*) FROM build_requests WHERE status = $1`, status).Scan(&count)
	return count, err
}

func (r *requestRepo) GetWeekendRequests(ctx context.Context, weekendStart time.Time) ([]domain.BuildRequest, error) {
	weekendEnd := weekendStart.AddDate(0, 0, 2) // Saturday + Sunday
	query := `
		SELECT id, user_id, title, description, request_type, status, complexity,
		       hosting_type, estimated_cost, is_free, builder_id, created_at
		FROM build_requests
		WHERE scheduled_weekend >= $1 AND scheduled_weekend < $2
		ORDER BY created_at ASC
	`
	rows, err := r.db.Query(ctx, query, weekendStart, weekendEnd)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var requests []domain.BuildRequest
	for rows.Next() {
		var req domain.BuildRequest
		if err := rows.Scan(
			&req.ID, &req.UserID, &req.Title, &req.Description,
			&req.RequestType, &req.Status, &req.Complexity,
			&req.HostingType, &req.EstimatedCost, &req.IsFree,
			&req.BuilderID, &req.CreatedAt,
		); err != nil {
			return nil, err
		}
		requests = append(requests, req)
	}
	return requests, nil
}
