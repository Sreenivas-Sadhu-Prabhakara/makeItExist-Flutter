-- Rollback: Drop all tables in reverse order
DROP TABLE IF EXISTS schedule_entries;
DROP TABLE IF EXISTS weekend_slots;
DROP TABLE IF EXISTS build_requests;
DROP TABLE IF EXISTS users;
DROP EXTENSION IF EXISTS "uuid-ossp";
