-- Migration: Add extended location fields to complaints
ALTER TABLE complaints ADD COLUMN street TEXT;
ALTER TABLE complaints ADD COLUMN area TEXT;
ALTER TABLE complaints ADD COLUMN ward TEXT;
ALTER TABLE complaints ADD COLUMN city TEXT;
