-- =============================================================================
-- NORTE BOUND — Migration 007: User Travel Preferences
-- MySQL 8.x / InnoDB / utf8mb4
-- =============================================================================

ALTER TABLE users
  ADD COLUMN travel_preferences JSON NULL AFTER role;
