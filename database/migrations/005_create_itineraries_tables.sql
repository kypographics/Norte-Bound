-- =============================================================================
-- NORTE BOUND — Migration 005: Itineraries & Scheduled Items
-- MySQL 8.x / InnoDB / utf8mb4
-- =============================================================================

CREATE TABLE itineraries (
  id                     INT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id                INT UNSIGNED NOT NULL,
  title                  VARCHAR(200) NOT NULL,
  total_days             INT UNSIGNED NOT NULL DEFAULT 1,
  total_estimated_cost   DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  preferences_snapshot   JSON NULL,
  created_at             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_itineraries_user (user_id),
  KEY idx_itineraries_created (created_at),
  CONSTRAINT chk_itineraries_total_days CHECK (total_days >= 1),
  CONSTRAINT chk_itineraries_total_cost CHECK (total_estimated_cost >= 0),
  CONSTRAINT fk_itineraries_user
    FOREIGN KEY (user_id) REFERENCES users (id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Saved itinerary headers with confirmed preference snapshots.';

CREATE TABLE itinerary_items (
  id                            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  itinerary_id                  INT UNSIGNED NOT NULL,
  destination_id                INT UNSIGNED NOT NULL,
  day_number                    INT UNSIGNED NOT NULL,
  sequence_order                INT UNSIGNED NOT NULL,
  scheduled_time                VARCHAR(16) NULL,
  meal_window                   VARCHAR(16) NULL,
  estimated_duration_minutes    INT UNSIGNED NOT NULL DEFAULT 0,
  travel_time_from_prev_minutes INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uq_itinerary_items_order (itinerary_id, day_number, sequence_order),
  KEY idx_itinerary_items_itinerary (itinerary_id),
  KEY idx_itinerary_items_destination (destination_id),
  CONSTRAINT chk_itinerary_items_day CHECK (day_number >= 1),
  CONSTRAINT chk_itinerary_items_sequence CHECK (sequence_order >= 1),
  CONSTRAINT chk_itinerary_items_duration CHECK (estimated_duration_minutes >= 0),
  CONSTRAINT chk_itinerary_items_travel CHECK (travel_time_from_prev_minutes >= 0),
  CONSTRAINT chk_itinerary_items_meal_window
    CHECK (meal_window IS NULL OR meal_window IN ('breakfast', 'lunch', 'merienda', 'dinner')),
  CONSTRAINT fk_itinerary_items_itinerary
    FOREIGN KEY (itinerary_id) REFERENCES itineraries (id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_itinerary_items_destination
    FOREIGN KEY (destination_id) REFERENCES destinations (id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Ordered, time-window-scheduled stops belonging to an itinerary.';
