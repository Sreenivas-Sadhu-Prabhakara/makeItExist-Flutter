# 🚀 Make It Exist

> **Build it. Ship it. Weekend warriors at your service.**

An enterprise-grade platform exclusive to **AIM students** — submit requests for websites & mobile apps, and we build them over the weekend (Saturday + Sunday, 8 hours/day).

---

## 🎯 What Is This?

**Make It Exist** is a just-in-time build service where AIM students can:

1. **Request a Website** → **FREE** (built & deployed at no cost)
2. **Request a Mobile App** → **Pricing discussed with builder**
3. **Request Whitelabel Deployment** → **Pricing discussed with builder**

We build during **8-hour weekend sprints** (Saturday & Sunday). Projects are queued, prioritized, and shipped.
Pricing for non-free services is handled directly between the building engineer and the student — no in-app payments.

---

## 💰 Pricing Model

```
┌─────────────────────────┬──────────┬─────────────────────────────────────┐
│ Service                 │ Cost     │ Details                             │
├─────────────────────────┼──────────┼─────────────────────────────────────┤
│ Website Build           │ FREE     │ Built & deployed on free-tier hosts │
│ Mobile App Build        │ Discuss  │ Pricing discussed with builder     │
│ Free Hosting            │ FREE     │ Vercel / Replit / Heroku (student   │
│                         │          │ email-linked accounts)              │
│ Whitelabel Deployment   │ Discuss  │ Custom domain, branding, hosting    │
│                         │          │ — pricing discussed with builder    │
└─────────────────────────┴──────────┴─────────────────────────────────────┘
```

> **💡 No in-app payments.** Pricing for mobile apps and whitelabel deployments
> is discussed directly between the building engineer and the student.

---

## 🔄 Request Flow

```
                    ┌──────────────┐
                    │  AIM Student  │
                    │   Signs Up    │
                    └──────┬───────┘
                           │
                    ┌──────▼───────┐
                    │  Verify AIM  │
                    │  Student ID  │
                    └──────┬───────┘
                           │
              ┌────────────▼────────────┐
              │   Submit Build Request   │
              │  (Website / App / Both)  │
              └────────────┬────────────┘
                           │
              ┌────────────▼────────────┐
              │  Builder Reviews Request │
              │  & Contacts Student      │
              └────────────┬────────────┘
                           │
            ┌──────────────▼──────────────┐
            │  Pricing Discussed Offline   │
            │  (if applicable)             │
            └──────────────┬──────────────┘
                           │
            ┌──────────────▼──────────────┐
            │   Queued for Weekend Build   │
            │   (Sat-Sun, 8hrs/day)        │
            └──────────────┬──────────────┘
                           │
              ┌────────────▼────────────┐
              │     Build In Progress    │
              │  (Status: BUILDING)      │
              └────────────┬────────────┘
                           │
            ┌──────────────▼──────────────┐
            │       Hosting Decision       │
            └──────┬──────────────┬───────┘
                   │              │
          ┌────────▼────┐  ┌─────▼────────┐
          │ FREE HOST   │  │ WHITELABEL   │
          │ Vercel/     │  │ Custom host  │
          │ Replit/     │  │ + domain     │
          │ Heroku      │  │ (discussed)  │
          └────────┬────┘  └─────┬────────┘
                   │              │
            ┌──────▼──────────────▼──────┐
            │     ✅ DELIVERED            │
            │  Student gets live URL      │
            └─────────────────────────────┘
```

---

## 🏗 Tech Stack

| Layer      | Technology        | Why                                      |
|------------|-------------------|------------------------------------------|
| Frontend   | **Flutter**       | Single codebase → iOS, Android, Web      |
| Backend    | **Go (Gin)**      | Blazing fast, concurrent, enterprise-ready|
| Database   | **PostgreSQL**    | Rock-solid ACID, scalable, proven         |
| Auth       | **JWT + OTP**     | Stateless, secure, student-verified       |
| Hosting    | **Docker + K8s**  | Containerized, scalable, reproducible     |
| CI/CD      | **GitHub Actions** | Automated testing & deployment           |

---

## 📁 Project Structure

```
makeItExist/
├── backend/                    # Go API Server
│   ├── cmd/server/             # Entry point
│   ├── internal/
│   │   ├── config/             # Environment & app config
│   │   ├── domain/             # Domain models & interfaces
│   │   ├── handler/            # HTTP handlers (controllers)
│   │   ├── middleware/         # Auth, CORS, Rate limiting, Logging
│   │   ├── repository/        # Database layer (PostgreSQL)
│   │   ├── service/           # Business logic
│   │   └── router/            # Route definitions
│   ├── migrations/             # SQL migration files
│   ├── Dockerfile
│   └── go.mod
├── frontend/                   # Flutter App
│   ├── lib/
│   │   ├── core/              # Constants, theme, utils, network
│   │   ├── data/              # Models & repositories
│   │   ├── presentation/      # BLoCs, screens, widgets
│   │   └── routes/            # Navigation
│   └── pubspec.yaml
├── docker-compose.yml          # Full stack orchestration
├── Makefile                    # Dev commands
└── README.md                   # You are here
```

---

## 🚀 Quick Start

### Prerequisites
- Go 1.21+
- Flutter 3.16+
- PostgreSQL 15+
- Docker & Docker Compose

### 1. Clone & Setup
```bash
git clone https://github.com/your-org/makeitexist.git
cd makeitexist
cp backend/.env.example backend/.env
# Edit backend/.env with your database credentials
```

### 2. Run with Docker (Recommended)
```bash
docker-compose up --build
```

### 3. Run Manually
```bash
# Terminal 1: Backend
cd backend && go run cmd/server/main.go

# Terminal 2: Frontend
cd frontend && flutter run -d chrome
```

### 4. Run Migrations
```bash
make migrate-up
```

---

## 🔐 Authentication Flow

1. Student registers with **AIM email** (`@aim.edu` or verified institution domain)
2. OTP sent to email for verification
3. JWT token issued on successful verification
4. Token required for all authenticated endpoints
5. Admin role for build team members

---

## 📋 API Endpoints

| Method | Endpoint                  | Auth  | Description                    |
|--------|---------------------------|-------|--------------------------------|
| POST   | `/api/v1/auth/register`   | No    | Register new AIM student       |
| POST   | `/api/v1/auth/login`      | No    | Login with credentials         |
| POST   | `/api/v1/auth/verify-otp` | No    | Verify OTP                     |
| GET    | `/api/v1/requests`        | Yes   | List my requests               |
| POST   | `/api/v1/requests`        | Yes   | Submit new build request       |
| GET    | `/api/v1/requests/:id`    | Yes   | Get request details            |
| PUT    | `/api/v1/requests/:id`    | Admin | Update request status          |
| GET    | `/api/v1/schedule`        | Yes   | View build schedule            |
| GET    | `/api/v1/schedule/slots`  | Yes   | View available weekend slots   |
| GET    | `/api/v1/admin/dashboard` | Admin | Admin dashboard stats          |
| GET    | `/api/v1/admin/requests`  | Admin | All requests (admin view)      |
| PUT    | `/api/v1/admin/schedule`  | Admin | Manage build schedule          |

---

## 🏢 Enterprise Features

- ✅ Role-based access control (Student / Builder / Admin)
- ✅ Rate limiting per user
- ✅ Structured logging (JSON)
- ✅ Request tracing with correlation IDs
- ✅ Database connection pooling
- ✅ Graceful shutdown
- ✅ Health checks & readiness probes
- ✅ Input validation & sanitization
- ✅ CORS configuration
- ✅ API versioning

---

## 📄 License

MIT — Built with ❤️ for AIM students.

---

*"If it can be imagined, we'll Make It Exist."*
