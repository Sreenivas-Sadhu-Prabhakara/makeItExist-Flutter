-- ============================================
-- Make It Exist - Initial Database Schema
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- USERS TABLE
-- ============================================
CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email           VARCHAR(255) UNIQUE NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,
    full_name       VARCHAR(255) NOT NULL,
    student_id      VARCHAR(100) NOT NULL,
    role            VARCHAR(20) NOT NULL DEFAULT 'student' 
                    CHECK (role IN ('student', 'builder', 'admin')),
    is_verified     BOOLEAN NOT NULL DEFAULT FALSE,
    otp             VARCHAR(10),
    otp_expires_at  TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_student_id ON users(student_id);
CREATE INDEX idx_users_role ON users(role);

-- ============================================
-- BUILD REQUESTS TABLE
-- ============================================
CREATE TABLE build_requests (
    id                          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id                     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title                       VARCHAR(500) NOT NULL,
    description                 TEXT NOT NULL,
    request_type                VARCHAR(20) NOT NULL 
                                CHECK (request_type IN ('website', 'mobile_app', 'both')),
    status                      VARCHAR(30) NOT NULL DEFAULT 'pending'
                                CHECK (status IN (
                                    'pending', 'queued', 'scheduled',
                                    'building', 'review', 'deploying', 'completed',
                                    'cancelled', 'rejected'
                                )),
    complexity                  VARCHAR(20) NOT NULL DEFAULT 'basic'
                                CHECK (complexity IN ('basic', 'standard', 'advanced')),
    hosting_type                VARCHAR(20) NOT NULL DEFAULT 'vercel'
                                CHECK (hosting_type IN ('vercel', 'replit', 'heroku', 'whitelabel')),
    
    -- Whitelabel-specific
    whitelabel_domain           VARCHAR(255),
    whitelabel_branding         TEXT,
    whitelabel_hosting_platform VARCHAR(100),
    
    -- Technical details
    tech_requirements           TEXT,
    reference_links             TEXT,
    figma_link                  VARCHAR(500),
    
    -- Hosting (student account)
    hosting_email               VARCHAR(255),
    
    -- Pricing
    estimated_cost              DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    is_free                     BOOLEAN NOT NULL DEFAULT TRUE,
    
    -- Delivery
    delivery_url                VARCHAR(500),
    repo_url                    VARCHAR(500),
    
    -- Scheduling
    scheduled_weekend           DATE,
    builder_id                  UUID REFERENCES users(id),
    
    -- Timestamps
    created_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at                TIMESTAMPTZ
);

CREATE INDEX idx_build_requests_user_id ON build_requests(user_id);
CREATE INDEX idx_build_requests_status ON build_requests(status);
CREATE INDEX idx_build_requests_type ON build_requests(request_type);
CREATE INDEX idx_build_requests_scheduled ON build_requests(scheduled_weekend);
CREATE INDEX idx_build_requests_builder ON build_requests(builder_id);

-- ============================================
-- WEEKEND SLOTS TABLE
-- ============================================
CREATE TABLE weekend_slots (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date            DATE UNIQUE NOT NULL,
    day_of_week     VARCHAR(10) NOT NULL CHECK (day_of_week IN ('saturday', 'sunday')),
    total_hours     INT NOT NULL DEFAULT 8,
    booked_hours    INT NOT NULL DEFAULT 0,
    max_projects    INT NOT NULL DEFAULT 5,
    booked_projects INT NOT NULL DEFAULT 0,
    status          VARCHAR(20) NOT NULL DEFAULT 'available'
                    CHECK (status IN ('available', 'booked', 'full')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_weekend_slots_date ON weekend_slots(date);
CREATE INDEX idx_weekend_slots_status ON weekend_slots(status);

-- ============================================
-- SCHEDULE ENTRIES TABLE
-- ============================================
CREATE TABLE schedule_entries (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id      UUID NOT NULL REFERENCES build_requests(id) ON DELETE CASCADE,
    slot_id         UUID NOT NULL REFERENCES weekend_slots(id) ON DELETE CASCADE,
    builder_id      UUID REFERENCES users(id),
    estimated_hours INT NOT NULL DEFAULT 4,
    status          VARCHAR(30) NOT NULL DEFAULT 'scheduled',
    notes           TEXT,
    start_time      TIMESTAMPTZ NOT NULL,
    end_time        TIMESTAMPTZ NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_schedule_entries_request ON schedule_entries(request_id);
CREATE INDEX idx_schedule_entries_slot ON schedule_entries(slot_id);
CREATE INDEX idx_schedule_entries_builder ON schedule_entries(builder_id);

-- ============================================
-- SEED: Default Admin User
-- ============================================
-- Password: password (bcrypt hash)
INSERT INTO users (id, email, password_hash, full_name, student_id, role, is_verified)
VALUES (
    uuid_generate_v4(),
    'admin@aim.edu',
    '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', -- "password"
    'Admin',
    'ADMIN001',
    'admin',
    TRUE
);
