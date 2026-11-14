-- =============================================================================
-- NORTE BOUND — Migration 003: Destinations & Tag Associations
-- MySQL 8.x / InnoDB / utf8mb4
-- =============================================================================

CREATE TABLE destinations (
  id                  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  slug                VARCHAR(191) NOT NULL,
  name                VARCHAR(200) NOT NULL,
  lgu_code            VARCHAR(64) NOT NULL,
  category_code       VARCHAR(64) NOT NULL,
  description         TEXT NOT NULL,
  historical_background TEXT NULL,
  address             VARCHAR(255) NULL,
  latitude            DECIMAL(10,7) NOT NULL,
  longitude           DECIMAL(10,7) NOT NULL,
  entity_type         ENUM('attraction', 'food_establishment', 'cultural_experience', 'activity_hub') NOT NULL,
  popularity_tier     ENUM('iconic_hub', 'moderate', 'hidden_gem') NOT NULL DEFAULT 'moderate',
  highway_accessible  BOOLEAN NOT NULL DEFAULT FALSE,
  road_condition      ENUM('paved_all_weather', 'rough_patch', '4x4_or_trek_required') NOT NULL DEFAULT 'paved_all_weather',
  verification_status ENUM('verified', 'needs_field_verification') NOT NULL DEFAULT 'needs_field_verification',
  source_name         VARCHAR(255) NOT NULL,
  source_type         ENUM('provincial_tourism', 'lgu_official', 'dot_accredited', 'verified_establishment') NOT NULL,
  last_verified_date  DATE NOT NULL,
  created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_destinations_slug (slug),
  KEY idx_destinations_lgu (lgu_code),
  KEY idx_destinations_category (category_code),
  KEY idx_destinations_popularity (popularity_tier),
  KEY idx_destinations_entity_type (entity_type),
  KEY idx_destinations_verification (verification_status),
  KEY idx_destinations_lat_lng (latitude, longitude),
  CONSTRAINT chk_destinations_latitude  CHECK (latitude BETWEEN 17.80 AND 18.68),
  CONSTRAINT chk_destinations_longitude CHECK (longitude BETWEEN 120.40 AND 121.05),
  CONSTRAINT fk_destinations_lgu
    FOREIGN KEY (lgu_code) REFERENCES lgus (lgu_code)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_destinations_category
    FOREIGN KEY (category_code) REFERENCES categories (category_code)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Verified tourism destinations, culinary spots, and experiences.';

CREATE TABLE destination_tags (
  destination_id INT UNSIGNED NOT NULL,
  tag_slug       VARCHAR(64) NOT NULL,
  PRIMARY KEY (destination_id, tag_slug),
  KEY idx_destination_tags_tag (tag_slug),
  CONSTRAINT fk_destination_tags_destination
    FOREIGN KEY (destination_id) REFERENCES destinations (id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_destination_tags_tag
    FOREIGN KEY (tag_slug) REFERENCES interest_tags (tag_slug)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Many-to-many association between destinations and interest tags.';
