-- Migration: 0002_add_alias
-- Created: 2024-02-01
-- Note: SQLite doesn't support "IF NOT EXISTS" for ALTER TABLE ADD COLUMN
-- This migration may fail if already applied - that's expected behavior

-- Add alias column (will fail if exists - that's OK)
ALTER TABLE configs ADD COLUMN alias TEXT UNIQUE;

-- Create index (idempotent)
CREATE INDEX IF NOT EXISTS idx_configs_alias ON configs(alias);
