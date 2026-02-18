-- ============================================
-- CodeSapiens Networking Bingo - Supabase Schema
-- Run this in your Supabase SQL Editor
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- PROFILES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  linkedin_url TEXT NOT NULL,
  github_url TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- QUESTIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS questions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  text TEXT NOT NULL,
  order_index INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- SCANS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS scans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  scanner_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  scanned_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  question_id UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  -- Prevent duplicate scans for same question
  UNIQUE(scanner_id, question_id),
  -- Prevent self-scans
  CHECK (scanner_id != scanned_id)
);

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE scans ENABLE ROW LEVEL SECURITY;

-- Profiles: anyone authenticated can read (needed for QR lookup), only owner can write
CREATE POLICY "profiles_select" ON profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY "profiles_insert" ON profiles FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);
CREATE POLICY "profiles_update" ON profiles FOR UPDATE TO authenticated USING (auth.uid() = id);

-- Questions: public read for authenticated users
CREATE POLICY "questions_select" ON questions FOR SELECT TO authenticated USING (true);

-- Scans: users can only see and create their own scans
CREATE POLICY "scans_select" ON scans FOR SELECT TO authenticated USING (scanner_id = auth.uid());
CREATE POLICY "scans_insert" ON scans FOR INSERT TO authenticated WITH CHECK (scanner_id = auth.uid());

-- ============================================
-- SEED BINGO QUESTIONS
-- ============================================
INSERT INTO questions (text, order_index) VALUES
  ('Scan someone who uses Python 🐍', 1),
  ('Scan a Web Developer 🌐', 2),
  ('Scan someone from a different city 🏙️', 3),
  ('Scan a Mobile Developer 📱', 4),
  ('Scan someone who contributed to Open Source 🔓', 5),
  ('Scan a Backend Developer ⚙️', 6),
  ('Scan someone who built an AI project 🤖', 7),
  ('Scan a UI/UX Designer 🎨', 8),
  ('Scan someone who has won a Hackathon 🏆', 9)
ON CONFLICT DO NOTHING;
