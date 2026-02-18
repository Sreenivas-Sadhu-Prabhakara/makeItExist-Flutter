.PHONY: help dev backend frontend db migrate-up migrate-down docker-up docker-down test lint

# ============================================
# Make It Exist - Development Commands
# ============================================

help: ## Show this help
	@echo "Make It Exist - Development Commands"
	@echo "===================================="
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# --- Docker ---
docker-up: ## Start all services with Docker
	docker-compose up --build -d

docker-down: ## Stop all Docker services
	docker-compose down

docker-logs: ## View Docker logs
	docker-compose logs -f

# --- Backend ---
backend: ## Run Go backend locally
	cd backend && go run cmd/server/main.go

backend-build: ## Build Go backend binary
	cd backend && go build -o bin/server cmd/server/main.go

backend-test: ## Run backend tests
	cd backend && go test ./... -v -cover

# --- Frontend ---
frontend-web: ## Run Flutter app for web
	cd frontend && flutter run -d chrome

frontend-android: ## Run Flutter app on Android
	cd frontend && flutter run -d android

frontend-ios: ## Run Flutter app on iOS
	cd frontend && flutter run -d ios

frontend-build-web: ## Build Flutter for web
	cd frontend && flutter build web

frontend-build-apk: ## Build Flutter APK
	cd frontend && flutter build apk

# --- Database ---
db: ## Start PostgreSQL only
	docker-compose up -d postgres

migrate-up: ## Run database migrations
	docker exec -i mie-postgres psql -U makeitexist -d makeitexist < backend/migrations/001_initial_schema.up.sql

migrate-down: ## Rollback database migrations
	docker exec -i mie-postgres psql -U makeitexist -d makeitexist < backend/migrations/001_initial_schema.down.sql

# --- Development ---
dev: docker-up ## Start everything for development
	@echo "🚀 All services started!"
	@echo "  Backend: http://localhost:8080"
	@echo "  Health:  http://localhost:8080/health"
	@echo ""
	@echo "Run 'make frontend-web' to start the Flutter app"

clean: ## Clean build artifacts
	cd backend && rm -rf bin/
	cd frontend && flutter clean
	docker-compose down -v

lint: ## Lint all code
	cd backend && golangci-lint run
	cd frontend && flutter analyze
