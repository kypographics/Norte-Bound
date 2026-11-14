-- =============================================================================
-- NORTE BOUND — Migration 004: Operating Schedules & Pricing
-- MySQL 8.x / InnoDB / utf8mb4
-- =============================================================================

CREATE TABLE operating_hours (
  id                 INT UNSIGNED NOT NULL AUTO_INCREMENT,
  destination_id     INT UNSIGNED NOT NULL,
  day_of_week        TINYINT UNSIGNED NOT NULL COMMENT '0=Sunday ... 6=Saturday',
  opening_time       TIME NULL,
  closing_time       TIME NULL,
  is_24_hours        BOOLEAN NOT NULL DEFAULT FALSE,
  temporarily_closed BOOLEAN NOT NULL DEFAULT FALSE,
  PRIMARY KEY (id),
  UNIQUE KEY uq_operating_hours_destination_day (destination_id, day_of_week),
  KEY idx_operating_hours_destination (destination_id),
  CONSTRAINT chk_operating_hours_day CHECK (day_of_week BETWEEN 0 AND 6),
  CONSTRAINT fk_operating_hours_destination
    FOREIGN KEY (destination_id) REFERENCES destinations (id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Per-day operating schedule for each destination (7 rows per destination).';

CREATE TABLE pricing_tiers (
  id                       INT UNSIGNED NOT NULL AUTO_INCREMENT,
  destination_id           INT UNSIGNED NOT NULL,
  entrance_fee_adult       DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  entrance_fee_concession  DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  mandatory_activity_fee   DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  estimated_meal_min       DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  estimated_meal_max       DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  parking_fee              DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  is_free                  BOOLEAN NOT NULL DEFAULT TRUE,
  currency                 VARCHAR(3) NOT NULL DEFAULT 'PHP',
  PRIMARY KEY (id),
  UNIQUE KEY uq_pricing_tiers_destination (destination_id),
  CONSTRAINT chk_pricing_tiers_non_negative
    CHECK (
      entrance_fee_adult >= 0 AND
      entrance_fee_concession >= 0 AND
      mandatory_activity_fee >= 0 AND
      estimated_meal_min >= 0 AND
      estimated_meal_max >= 0 AND
      parking_fee >= 0
    ),
  CONSTRAINT fk_pricing_tiers_destination
    FOREIGN KEY (destination_id) REFERENCES destinations (id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Deterministic pricing snapshot for a destination (one row per destination).';
