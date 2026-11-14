# NORTE BOUND

**An AI-Assisted Context-Aware Tourism Recommendation and Dynamic Itinerary Planning System for Ilocos Norte**

NORTE BOUND helps travelers discover and plan grounded, realistic itineraries across all **22 Local Government Units (LGUs)** (20 municipalities and 2 component cities) of **Ilocos Norte, Philippines**. It pairs bounded natural-language preference extraction (Google Gemini) with a deterministic MySQL-backed multi-criteria scoring and time-window scheduling engine.

---

## Monorepo Structure

```text
norte-bound/
├── backend/                 # Node.js (ESM) + Express.js API & planning engine
│   └── src/
│       ├── config/          # Environment, MySQL pool, Gemini & routing clients
│       ├── controllers/     # HTTP handlers
│       ├── middlewares/     # JWT auth, RBAC guards, Zod validation, error handling
│       ├── models/          # Parameterized mysql2/promise SQL queries
│       ├── routes/          # Express route definitions
│       ├── schemas/         # Zod schemas for requests & AI structured outputs
│       ├── services/        # Scoring, itinerary scheduler, Gemini NL extraction
│       └── utils/           # Haversine + tortuosity math, time helpers
├── mobile/                  # Flutter + Dart client ("Cupertino Nature-First" UI)
├── database/                # MySQL 8.x schema, migrations, seeds, LGU research
│   ├── migrations/
│   ├── seeds/
│   └── research/
├── docs/                    # Architecture, requirements, and technical specifications
├── AGENTS.md                # Permanent engineering & UI/UX rules for contributors/AI
└── .gitignore
```

---

## Tech Stack

- **Mobile Client (`mobile/`):** Flutter, Dart, `flutter_riverpod`, `go_router`, `dio`, `flutter_map` (OpenStreetMap), `latlong2`
- **Backend API (`backend/`):** Node.js (ES Modules), Express.js, `mysql2/promise`, `zod`, `bcrypt`, `jsonwebtoken`
- **AI Preference Extraction:** Google Gemini API (`gemini-2.5-flash`) with Structured Outputs (`responseSchema`)
- **Maps & Routing:** OpenStreetMap, OSRM / OpenRouteService, Haversine + road tortuosity multiplier
- **Database:** MySQL 8.x (parameterized SQL queries; no ORM abstraction)

---

## Core Design Principles

1. **Zero-Hallucination Grounding:** Gemini is restricted strictly to parsing natural-language preferences into validated JSON. All destinations, coordinates, fees, and operating hours are served exclusively from verified MySQL records.
2. **Backend-Centralized Intelligence:** All multi-criteria scoring ($S_{total}$), constraint relaxation diagnostics, budget validation, meal injection, and time-window scheduling reside in Node.js services.
3. **Cupertino Nature-First UI:** Crafted with Deep Forest Green (`#092008`), Warm Sand Beige (`#F5E6D3`), Elevated Ivory Sand (`#FAF4EC`), Sky Blue (`#87CEEB`), and Terracotta Orange (`#E27D5A`) following Apple HIG patterns.

---

## Development Roadmap

- **Phase 1.1 (Current):** Project Foundation, Monorepo Scaffolding, Git Configuration, `AGENTS.md`, and Requirements/Architecture Documentation
- **Phase 1.2:** MySQL 8.x Schema Design, 22-LGU & Destination Dataset Curation, Migrations & Seed Scripts
- **Phase 2:** Backend Core API (Auth/RBAC, Discovery Endpoints, Gemini NL Extraction, Recommendation & Dynamic Scheduling Engine)
- **Phase 3:** Flutter Mobile Application ("Cupertino Nature-First" UI, Interactive `flutter_map`, Preference Confirmation & Stop Swapping)
- **Phase 4:** Integration Testing, ISO/IEC 25010 Verification, and Polishing
