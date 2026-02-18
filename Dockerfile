# ============================================
# Stage 1: Build Flutter Web
# ============================================
FROM ghcr.io/cirruslabs/flutter:3.22.2-dart-3.6.0 AS flutter-builder

WORKDIR /app/frontend
COPY frontend/ .

RUN flutter pub get
RUN flutter build web --release --no-web-resources-cdn

# ============================================
# Stage 2: Build Go Binary
# ============================================
FROM golang:1.23-alpine AS go-builder

WORKDIR /app

RUN apk add --no-cache git ca-certificates

COPY backend/go.mod backend/go.sum* ./
RUN go mod download

COPY backend/ .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o server ./cmd/server

# ============================================
# Stage 3: Final Minimal Image
# ============================================
FROM alpine:3.19

RUN apk --no-cache add ca-certificates tzdata

WORKDIR /app

# Copy Go binary
COPY --from=go-builder /app/server .

# Copy DB migrations
COPY --from=go-builder /app/migrations ./migrations

# Copy built Flutter web output
COPY --from=flutter-builder /app/frontend/build/web ./static

# The Go server reads FRONTEND_DIR to find static files
ENV FRONTEND_DIR=/app/static
ENV SERVER_PORT=8080
ENV SERVER_ENV=production

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -qO- http://localhost:8080/health || exit 1

CMD ["./server"]
