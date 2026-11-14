-- =============================================================================
-- NORTE BOUND — Migration 006: Optional Source Attribution
-- Allows admin-curated destinations to be created without source metadata.
-- Source fields must still be provided for records marked as verified through
-- the API validation layer and data collection standard.
-- =============================================================================

ALTER TABLE destinations
  MODIFY COLUMN source_name VARCHAR(255) NULL,
  MODIFY COLUMN source_type ENUM('provincial_tourism', 'lgu_official', 'dot_accredited', 'verified_establishment') NULL,
  MODIFY COLUMN last_verified_date DATE NULL;
