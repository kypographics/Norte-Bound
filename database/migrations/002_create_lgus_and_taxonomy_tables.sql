-- =============================================================================
-- NORTE BOUND — Migration 002: LGUs & Controlled Taxonomy
-- MySQL 8.x / InnoDB / utf8mb4
-- =============================================================================

CREATE TABLE lgus (
  lgu_code                   VARCHAR(64) NOT NULL,
  name                       VARCHAR(150) NOT NULL,
  lgu_type                   ENUM('municipality', 'component_city') NOT NULL,
  tourism_cluster            VARCHAR(64) NOT NULL,
  center_latitude            DECIMAL(10,7) NOT NULL,
  center_longitude           DECIMAL(10,7) NOT NULL,
  terrain_type               VARCHAR(64) NOT NULL,
  road_tortuosity_multiplier DECIMAL(3,2) NOT NULL,
  is_major_hub               BOOLEAN NOT NULL DEFAULT FALSE,
  baseline_dispersal_bonus   DECIMAL(3,2) NOT NULL DEFAULT 0.00,
  created_at                 TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at                 TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (lgu_code),
  UNIQUE KEY uq_lgus_name (name),
  KEY idx_lgus_cluster (tourism_cluster),
  KEY idx_lgus_type (lgu_type),
  KEY idx_lgus_major_hub (is_major_hub),
  CONSTRAINT chk_lgus_latitude  CHECK (center_latitude BETWEEN 17.80 AND 18.68),
  CONSTRAINT chk_lgus_longitude CHECK (center_longitude BETWEEN 120.40 AND 121.05),
  CONSTRAINT chk_lgus_tortuosity CHECK (road_tortuosity_multiplier BETWEEN 1.20 AND 1.60),
  CONSTRAINT chk_lgus_dispersal CHECK (baseline_dispersal_bonus BETWEEN 0.00 AND 1.00)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Official 23 LGUs of Ilocos Norte with routing/dispersal parameters.';

CREATE TABLE categories (
  category_code VARCHAR(64) NOT NULL,
  name          VARCHAR(150) NOT NULL,
  description   TEXT NOT NULL,
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (category_code),
  UNIQUE KEY uq_categories_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Primary destination classification taxonomy.';

CREATE TABLE interest_tags (
  tag_slug      VARCHAR(64) NOT NULL,
  display_name  VARCHAR(150) NOT NULL,
  category_code VARCHAR(64) NOT NULL,
  ai_synonyms   JSON NULL,
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (tag_slug),
  KEY idx_interest_tags_category (category_code),
  CONSTRAINT fk_interest_tags_category
    FOREIGN KEY (category_code) REFERENCES categories (category_code)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='Granular interest tags used by Gemini intent mapping.';
