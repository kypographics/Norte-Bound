# NORTE BOUND

> **An AI-Assisted Context-Aware Tourism Recommendation and Dynamic Itinerary Planning System for Ilocos Norte, Philippines**

NORTE BOUND covers all **22 Local Government Units (LGUs)** (20 municipalities and 2 component cities: Laoag City and Batac City) of Ilocos Norte. The system combines deterministic multi-criteria recommendation scoring, time-window itinerary scheduling, and interactive mapping with bounded natural-language preference extraction via Google Gemini.

---

## 📂 Monorepo Structure

```text
NORTE-BOUND-NEW/
├── backend/                  # Node.js + Express REST API
│   └── src/
│       ├── config/           # DB pool, environment config, external API clients
│       ├── controllers/      # HTTP request/response orchestration
│       ├── middlewares/      # JWT authentication, RBAC guards, Zod validation
│       ├── models/           # Parameterized MySQL queries
│       ├── routes/           # Express route definitions
│       ├── schemas/          # Zod schemas (request validation & Gemini structured output)
│       ├── services/         # Recommendation engine, scheduler, Gemini service, auth
│       └── utils/            # Pure helpers (Haversine distance, time math, formatters)
├── mobile/                   # Flutter cross-platform client app
├── database/
│   ├── migrations/           # MySQL 8.x DDL schema migration scripts
│   ├── seeds/                # Initial seed data for 22 LGUs and destination records
│   └── research/             # Tourism metadata research & citation snapshots
├── docs/                     # Architecture, requirements, and API specifications
├── AGENTS.md                 # Master OpenCode context & engineering guardrails
└── README.md
```

---

## 🛠️ Tech Stack

- **Frontend (`mobile/`):** Flutter, Riverpod (`flutter_riverpod`), `go_router`, `dio`, `flutter_map`, `latlong2`.
- **Backend (`backend/`):** Node.js (ES Modules, `"type": "module"`), Express.js, `pg` (Supabase PostgreSQL), `zod`, `bcrypt`, `jsonwebtoken`.
- **AI Engine:** Google Gemini API (`gemini-2.5-flash`) with Structured Outputs (`responseSchema`).
- **Routing & Maps:** OpenStreetMap + OSRM / OpenRouteService (with Haversine road tortuosity matrix scoring).
- **Database (`database/`):** Supabase (PostgreSQL 17 with Row-Level Security and parameterized SQL only, no ORMs hiding queries).

---

## 🗺️ Development Roadmap

- **Phase 1: Foundation & Scaffolding** (Monorepo setup, architectural docs, database schema design)
- **Phase 2: Backend Core Services & MySQL Integration** (Auth, LGU discovery, Gemini preference parser, recommendation engine)
- **Phase 3: Itinerary Scheduler & REST API Integration** (Time-window greedy scheduler, expense breakdown, Express endpoints)
- **Phase 4: Flutter Mobile App Development** (Cupertino Nature-First UI, state management, map integration)
- **Phase 5: Testing, Polish & Deployment** (End-to-end verification, performance tuning, production readiness)
