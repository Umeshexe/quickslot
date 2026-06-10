-- QuickSlot Database Schema
-- Run this once against your Neon/Postgres DB to create all tables

CREATE TABLE IF NOT EXISTS venues (
  id          SERIAL PRIMARY KEY,
  name        TEXT NOT NULL,
  sport_type  TEXT NOT NULL CHECK (sport_type IN ('badminton', 'turf', 'cricket', 'basketball')),
  location    TEXT NOT NULL,
  image_url   TEXT,
  price_inr   INT NOT NULL DEFAULT 500,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS slots (
  id          SERIAL PRIMARY KEY,
  venue_id    INT NOT NULL REFERENCES venues(id) ON DELETE CASCADE,
  date        DATE NOT NULL,
  start_time  TIME NOT NULL,
  end_time    TIME NOT NULL,
  status      TEXT NOT NULL DEFAULT 'available' CHECK (status IN ('available', 'booked')),
  UNIQUE(venue_id, date, start_time)  -- DB-level guard: no duplicate slots
);

-- Index to speed up the most common query: all slots for a venue on a date
CREATE INDEX IF NOT EXISTS idx_slots_venue_date ON slots(venue_id, date);

CREATE TABLE IF NOT EXISTS bookings (
  id          SERIAL PRIMARY KEY,
  user_id     TEXT NOT NULL,              -- hardcoded: user-001, user-002, user-003
  slot_id     INT NOT NULL REFERENCES slots(id) ON DELETE RESTRICT,
  booked_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(slot_id)  -- one booking per slot, enforced at DB level too
);
