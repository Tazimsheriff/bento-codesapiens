-- ============================================
-- CyberExplore TEMS - Supabase Schema
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
  qr_token TEXT UNIQUE NOT NULL,
  xp INTEGER DEFAULT 0,
  is_admin BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Migrations for existing tables
DO $$ 
BEGIN 
    -- Add linkedin_url if missing (migration from old version)
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='profiles' AND COLUMN_NAME='linkedin_url') THEN
        ALTER TABLE profiles ADD COLUMN linkedin_url TEXT DEFAULT '';
    END IF;

    -- Add qr_token if missing
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='profiles' AND COLUMN_NAME='qr_token') THEN
        ALTER TABLE profiles ADD COLUMN qr_token TEXT UNIQUE;
        -- Generate tokens for existing users if any
        UPDATE profiles SET qr_token = uuid_generate_v4()::text WHERE qr_token IS NULL;
    END IF;

    -- Add xp if missing
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='profiles' AND COLUMN_NAME='xp') THEN
        ALTER TABLE profiles ADD COLUMN xp INTEGER DEFAULT 0;
    END IF;

    -- Add is_admin if missing
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='profiles' AND COLUMN_NAME='is_admin') THEN
        ALTER TABLE profiles ADD COLUMN is_admin BOOLEAN DEFAULT FALSE;
    END IF;

    -- Drop github_url if it exists
    IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='profiles' AND COLUMN_NAME='github_url') THEN
        ALTER TABLE profiles DROP COLUMN github_url;
    END IF;
END $$;

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
DROP POLICY IF EXISTS "profiles_select" ON profiles;
DROP POLICY IF EXISTS "profiles_insert" ON profiles;
DROP POLICY IF EXISTS "profiles_update" ON profiles;
CREATE POLICY "profiles_select" ON profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY "profiles_insert" ON profiles FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);
CREATE POLICY "profiles_update" ON profiles FOR UPDATE TO authenticated USING (auth.uid() = id);

-- Questions: public read for authenticated users
DROP POLICY IF EXISTS "questions_select" ON questions;
CREATE POLICY "questions_select" ON questions FOR SELECT TO authenticated USING (true);

-- Scans: users can only see and create their own scans
DROP POLICY IF EXISTS "scans_select" ON scans;
DROP POLICY IF EXISTS "scans_insert" ON scans;
CREATE POLICY "scans_select" ON scans FOR SELECT TO authenticated USING (scanner_id = auth.uid());
CREATE POLICY "scans_insert" ON scans FOR INSERT TO authenticated WITH CHECK (scanner_id = auth.uid());

-- ============================================
-- SEED BINGO QUESTIONS (Cyber & Dev Edition)
-- ============================================
TRUNCATE TABLE questions CASCADE;
INSERT INTO questions (text, order_index) VALUES
  ('🕵️ Scan someone who loves OSINT', 1),
  ('🔎 Scan someone who uses Google Dorking', 2),
  ('🌐 Scan someone who does Subdomain Enumeration', 3),
  ('🧠 Scan someone who reads CVEs regularly', 4),
  ('💉 Scan someone who knows SQL Injection', 5),
  ('⚡ Scan someone who crafts XSS payloads', 6),
  ('🔐 Scan someone who understands authentication bugs', 7),
  ('🪪 Scan someone who has tried IDOR exploitation', 8),
  ('📡 Scan someone who uses Nmap', 9),
  ('🦈 Scan someone who uses Wireshark', 10),
  ('🔄 Scan someone who has done MITM attacks', 11),
  ('📶 Scan someone interested in wireless security', 12),
  ('🧪 Scan someone who has analyzed malware', 13),
  ('🔍 Scan someone who uses Ghidra or IDA', 14),
  ('🐍 Scan someone who writes security scripts', 15),
  ('🏁 Scan someone who plays CTFs', 16),
  ('🐞 Scan someone doing Bug Bounty', 17),
  ('💰 Scan someone who found a vulnerability', 18),
  ('🛡️ Scan someone interested in Blue Team', 19),
  ('🚨 Scan someone who works in SOC / monitoring', 20),
  ('😈 Scan a Red Teamer', 21),
  ('🧑‍💻 Scan a Linux nerd', 22),
  ('🔐 Scan a password cracking wizard', 23),
  ('🤖 Scan someone exploring AI security', 24),
  ('🌐 Scan a Web Developer', 25),
  ('📱 Scan a Mobile App Developer', 26),
  ('🖥️ Scan a Backend Developer', 27),
  ('⚛️ Scan someone who uses React', 28),
  ('🐍 Scan someone who codes in Python', 29),
  ('☕ Scan a Java Developer', 30),
  ('📊 Scan a Data Analyst', 31),
  ('🤖 Scan someone exploring AI/ML', 32),
  ('🧠 Scan someone building an AI project', 33),
  ('🎨 Scan a Canva Poster Expert', 34),
  ('✍️ Scan a Content Creator', 35),
  ('🎬 Scan someone who edits videos', 36),
  ('🖌️ Scan a UI/UX Designer', 37),
  ('📸 Scan someone who loves photography', 38),
  ('🏙️ Scan someone from a different city', 39),
  ('🧑‍🤝‍🧑 Scan someone attending their first hackathon', 40),
  ('🎤 Scan someone who has spoken on stage', 41),
  ('🏆 Scan someone who won a hackathon', 42),
  ('☕ Scan someone who runs on coffee', 43)
ON CONFLICT DO NOTHING;

-- ============================================
-- RPC FUNCTIONS
-- ============================================

-- Function to increment user XP
CREATE OR REPLACE FUNCTION increment_xp(user_id UUID, amount INTEGER)
RETURNS VOID AS $$
BEGIN
  UPDATE profiles
  SET xp = xp + amount
  WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to reset leaderboard
CREATE OR REPLACE FUNCTION reset_leaderboard()
RETURNS VOID AS $$
BEGIN
  UPDATE profiles
  SET xp = 0;
  
  -- Optionally clear all scans too if a full reset is desired
  -- DELETE FROM scans;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- ADMIN POLICIES
-- ============================================

-- Only admins can insert/update/delete questions
DROP POLICY IF EXISTS "questions_admin" ON questions;
CREATE POLICY "questions_admin" ON questions 
  FOR ALL TO authenticated 
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE));
