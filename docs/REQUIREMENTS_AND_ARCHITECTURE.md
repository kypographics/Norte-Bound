# NORTE BOUND: Requirements and System Architecture (Case Study Revision 3)

## 1. System Overview & Academic Scope

**NORTE BOUND** is an AI-assisted, context-aware tourism recommendation and dynamic itinerary planning system covering all **23 official Local Government Units (LGUs)** (21 municipalities and 2 component cities: Laoag City and Batac City) of **Ilocos Norte, Philippines**, organized into **4 tourism circuits**:
1. **Northern Coast** (`northern_coast`)
2. **Central Urban Heritage** (`central_urban_heritage`)
3. **Southern Heritage Coast** (`southern_heritage_coast`)
4. **Eastern Agri-Highland** (`eastern_agri_highland`)

Grounded in Ilocos Norte Tourism Office statistics (4.3M visitor arrivals and ₱10.4B revenue in 2024; Adriano, 2025) and a platform gap review (Mar 2025 – Nov 2026), NORTE BOUND unifies verified provincial destination data, GPS/location context, natural-language preference interpretation, multi-criteria recommendation scoring, time-window itinerary generation, and dynamic itinerary recalculation into a single platform.

---

## 2. Case Study Revision 3 Research Questions & Objectives Alignment

### A. Research Questions (RQ1–RQ7)
- **RQ1 (Planning Efficiency):** How does NORTE BOUND compare with manual travel planning in the time needed to find destinations and build a feasible itinerary? *(Target: $\ge 20\%$ reduction in average planning time).*
- **RQ2 (GPS Context):** How does GPS-based location data enable destination suggestions for tourists inside Ilocos Norte (with manual LGU/coordinate fallback when GPS is off or outside the province)?
- **RQ3 (Feasible Scheduling):** How does NORTE BOUND construct travel plans respecting available time, budget, interests, chosen activities, travel distance, travel time, and destination opening hours?
- **RQ4 (AI Preference Extraction):** How accurately does NORTE BOUND convert natural-language requests into structured preferences across 6 core dimensions? *(Target: $\ge 85\%$ exact match across $\ge 50$ held-out prompts).*
- **RQ5 (Change-Detection Matrix):** Which itinerary changes can NORTE BOUND detect automatically versus which require user or administrator input?
- **RQ6 (Lesser-Known & Community-Based Inclusion):** To what extent do lesser-known (`hidden_gem`) and community-based destinations appear in recommendations and itineraries? *(Target: $\ge 30\%$ inclusion whenever qualifying feasible options exist).*
- **RQ7 (Platform Benchmark):** How does NORTE BOUND compare with Google Maps in user satisfaction, recommendation relevance, and task ease on a 5-point Likert scale?

### B. System-Development Objectives (Sys-Obj A.1–A.8) & Functional Requirements

| Objective | Requirement ID | Architectural Implementation |
| :--- | :--- | :--- |
| **A.1 Cross-Platform App** | `FR-AUTH`, `FR-APP` | Flutter (Android & iOS) + Node.js/Express REST API + JWT RBAC (`tourist`, `admin`). |
| **A.2 Verified Tourism DB** | `FR-DATA` | Supabase PostgreSQL 17 (`NorteBound` project `ewqohgqsuaisivvbavfy`) with 69 destinations across 23 LGUs, 7-day schedules (483 slots), PHP pricing tiers, and Row-Level Security (RLS) on all tables. **Hard Rule:** Records with `verification_status != 'verified'` (i.e. `'needs_field_verification'`) or `temporarily_closed = true` are strictly excluded from itinerary generation. |
| **A.3 Interactive Tourism Map** | `FR-MAP` | `flutter_map` (OpenStreetMap tiles) rendering verified pins, categories, user GPS/manual origin, and consecutive stop route polylines via OSRM / Haversine tortuosity routing. |
| **A.4 GPS Context Recommendations** | `FR-REC` | Multi-criteria weighted scoring incorporating GPS/origin proximity, interests, time, budget, and dispersal bonus. |
| **A.5 AI Preference Interpretation** | `FR-PREF` | `gemini-2.5-flash` Structured Outputs (`responseSchema`) + Zod validation + deterministic synonym/LGU rule fallback extracting: (1) `destinationType`, (2) `activityType`, (3) `budgetLevel`, (4) `preferredScenery`, (5) `preferredArea`, and (6) `availableTime`. Requires explicit user confirmation before scoring. |
| **A.6 Feasible Itinerary Generation** | `FR-ITIN` | Time-window greedy scheduler calculating entrance fees, mandatory activity/parking fees, meal windows (`lunch`/`dinner`), and local transport estimates, verified against the 5-condition Feasibility Rule. |
| **A.7 Dynamic Itinerary Adjustment** | `FR-DYN` | Recalculates remaining stops in **$< 10\text{ seconds}$** when user modifies time, budget, preferences, or location, or when an admin updates destination availability/hours in `admin-web/`. |
| **A.8 $\ge 30\%$ Dispersal Quota Rule** | `FR-DISP` | Ensures $\ge 30\%$ of recommended and scheduled stops are lesser-known (`hidden_gem`) or community-based (`is_community_based = 1`) whenever qualifying feasible candidates exist. |

### C. Quantitative Research-Evaluation Targets (Eval-Obj B.1–B.9)
1. **B.1 Recommendation Relevance:** $\ge 80\%$ of rated recommendations score $\ge 4.0 / 5.0$ ($\ge 10$ spots rated per evaluator).
2. **B.2 AI Extraction Accuracy:** $\ge 85\%$ exact field match across $\ge 50$ held-out natural-language requests.
3. **B.3 Feasibility Compliance:** 100% deterministic verification of the 5 feasibility conditions with explicit violated-constraint reporting.
4. **B.4 Planning Time Reduction:** $\ge 20\%$ reduction vs. manual planning on identical scenarios.
5. **B.5 Dynamic Recalculation Latency:** $< 10\text{ seconds}$ average recalculation time for itineraries with $\le 10$ stops across all supported user/admin changes.
6. **B.6 Lesser-Known / Community Quota:** $\ge 30\%$ representation without overriding user constraints or itinerary feasibility.
7. **B.7 Usability & Acceptance:** $\ge 4.0 / 5.0$ Likert average across $\ge 50$ respondents.
8. **B.8 Google Maps Comparison:** Higher average Likert ratings on satisfaction, relevance, and task ease.
9. **B.9 Change-Detection Matrix:** Accurate classification and handling of automatic vs. manual-input itinerary changes.

---

## 3. Formal Algorithmic Definitions (Backend Core)

### A. 9-Step System Process Pipeline (Revision 3 Section IV.A.1)
1. **User Input Collection** → Collect interests, budget, available time, transport mode, group size, and pacing.
2. **Location Acquisition** → Acquire device GPS coordinates (with permission) or manual LGU origin fallback.
3. **Preference Interpretation** → Convert natural-language prompt into validated 6-dimension JSON + user confirmation gate.
4. **Destination Filtering** → Prune unverified (`verification_status != 'verified'`), closed, out-of-area, or over-budget destinations.
5. **Recommendation Generation** → Score candidates via $S_{\text{total}}$ and apply the $\ge 30\%$ lesser-known/community quota selector.
6. **Recommendation Explanation** → Attach transparent match % and human-readable reason badges to each candidate.
7. **Itinerary Generation** → Sequence stops into daily time windows, inject meal stops, compute transport/entry/meal costs, and run the 5-Condition Feasibility Verifier.
8. **Context Monitoring** → Diff active itineraries against live MySQL destination status/hours/fees and user time/location context.
9. **Itinerary Adjustment** → Re-sequence remaining stops and suggest replacements in $< 10\text{ seconds}$.

### B. Multi-Criteria Recommendation Scoring Formula
For each candidate destination $d$ surviving hard filtering:

$$S_{\text{total}}(d) = w_1 S_{\text{interest}}(d) + w_2 S_{\text{budget}}(d) + w_3 S_{\text{proximity}}(d) + w_4 S_{\text{duration}}(d) + w_5 S_{\text{dispersal}}(d)$$

- **$S_{\text{interest}} \in [0, 1]$:** Weighted match of `category_code`, `destination_tags` (`activityType`), and LGU `terrain_type` (`preferredScenery`).
- **$S_{\text{budget}} \in [0, 1]$:** Affordability score based on `(entrance_fee_adult + mandatory_activity_fee)` vs. per-stop budget allowance.
- **$S_{\text{proximity}} \in [0, 1]$:** Distance decay from current GPS / origin LGU using Haversine distance $\times$ LGU `road_tortuosity_multiplier`.
- **$S_{\text{duration}} \in [0, 1]$:** Compatibility of `estimated_visit_duration_minutes` with available daily hours and travel pacing.
- **$S_{\text{dispersal}} \in [0, 1]$:** Normalized LGU `baseline_dispersal_bonus` + priority boost for `popularity_tier = 'hidden_gem'` or `is_community_based = 1`.

### C. 5-Condition Feasible Itinerary Rule (Revision 3 pp. 4, 7–8)
An itinerary is classified as **Feasible** (`isFeasible: true`) iff all 5 conditions hold:
1. **Time Budget Compliance:** $\sum T_{\text{travel}} + \sum T_{\text{visit}} \le T_{\text{available}}$.
2. **Operating Hour Compliance:** For every stop $i$, $\text{opening\_time}_i \le t_{\text{arrival}, i}$ and $t_{\text{departure}, i} \le \text{closing\_time}_i$ on the scheduled `day_of_week`, with `temporarily_closed = 0`.
3. **Financial Budget Compliance:** $C_{\text{total}} = C_{\text{entry\_activity}} + C_{\text{parking}} + C_{\text{meals}} + C_{\text{transport}} \le B_{\text{user}}$.
4. **Time-Window Boundary Compliance:** Each day starts $\ge t_{\text{day\_start}}$ and ends $\le t_{\text{day\_end}}$.
5. **Route Calculability:** Finite distance and travel duration exist between every consecutive stop pair $(i, i+1)$.

If any condition fails, `isFeasible = false` and `violatedConstraints` lists the exact failed condition(s) and offending stop/budget values.

### D. Change-Detection Matrix (RQ5 & Eval-Obj B.9)

| Change Event | Detection Mode | Trigger Source | System Response |
| :--- | :--- | :--- | :--- |
| **Destination Closure** (`temporarily_closed = 1` or status $\ne$ `verified`) | **Automatic** (DB state diff on load/check) | Admin (`admin-web/`) | Flags affected stop as unavailable; replaces with nearest feasible candidate in $< 10\text{s}$. |
| **Operating Schedule Shift** (`opening_time` / `closing_time` updated) | **Automatic** (Time-window collision check) | Admin (`admin-web/`) | Re-verifies arrival/departure window; re-orders or swaps conflicting stop. |
| **Fee / Price Update** (`entrance_fee_adult` / `mandatory_activity_fee`) | **Automatic** (Budget re-sum check) | Admin (`admin-web/`) | Recalculates $C_{\text{total}}$; alerts user if $C_{\text{total}} > B_{\text{user}}$ and offers lower-cost swap. |
| **GPS Location / Elapsed Time Drift** | **Automatic** (GPS / clock check) or **Manual Override** | Device GPS / Tourist | Recomputes remaining time window & proximity from current LGU. |
| **Available Time / Budget / Preference Change** | **Manual User Input** | Tourist (App UI) | Re-runs filtered scheduler on remaining stops in $< 10\text{s}$. |
| **Stop Swap / Removal / Reorder** | **Manual User Input** | Tourist (App UI) | Recomputes leg travel times, meal windows, expenses, and 5-condition feasibility. |

---

## 4. Monorepo & API Architecture

```text
NORTE BOUND NEW/
├── backend/                  # Node.js + Express (ESM) REST API (Port 5000)
│   └── src/
│       ├── config/           # env.mjs (Zod), db.mjs (mysql2 pool)
│       ├── schemas/          # auth, destination, recommendation, itinerary Zod schemas
│       ├── models/           # Parameterized SQL queries (user, destination, itinerary)
│       ├── services/         # ai.intent, recommendation, itinerary, change-detection
│       ├── controllers/      # HTTP request/response orchestration
│       ├── middlewares/      # JWT verifyToken, requireRole, validate, errorHandler
│       ├── routes/           # /health, /auth, /destinations, /admin/destinations, /recommendations, /itineraries
│       └── utils/            # destination.mapper.mjs, geo.matrix.mjs
├── mobile/                   # Flutter (Android/iOS) Client — Riverpod + go_router + dio + flutter_map
├── admin-web/                # Isolated Web Admin Portal for curator CRUD & verification status
├── database/                 # MySQL 8.x migrations (001–008) & idempotent seed runner
└── docs/                     # REQUIREMENTS_AND_ARCHITECTURE.md, DESIGN.md, IMPLEMENTATION_PLAN.md
```

### REST API Contract Summary (`/api/v1`)
- **Health & Auth:** `GET /health`, `POST /auth/register`, `POST /auth/login`, `GET /auth/me`, `PUT /auth/profile`, `PUT /auth/password`
- **Public Discovery:** `GET /destinations/lgus`, `GET /destinations/taxonomy`, `GET /destinations`, `GET /destinations/:slug`
- **Admin Curation (`admin` RBAC):** `POST /admin/destinations`, `PUT /admin/destinations/:id`, `PATCH /admin/destinations/:id/status`, `DELETE /admin/destinations/:id`
- **AI Intent & Recommendations (`tourist` / authenticated):**
  - `POST /recommendations/parse-intent` — Extracts 6-dimension preferences via Gemini `responseSchema` + deterministic fallback.
  - `POST /recommendations` — Returns scored candidates, $\ge 30\%$ lesser-known/community quota stats, explainability reasons, and constraint-relaxation diagnostics.
- **Dynamic Itineraries (`tourist` / authenticated):**
  - `POST /itineraries/generate` — Generates or recalculates (`<10s`) a day-by-day schedule, meal windows, expense breakdown, 5-condition `feasibilityReport`, and `changeDetectionReport`.
  - `POST /itineraries`, `GET /itineraries`, `GET /itineraries/:id`, `DELETE /itineraries/:id` — Saved itinerary CRUD (`GET /itineraries/:id` automatically diffs saved stops against live MySQL destination hours, `verification_status`, `temporarily_closed`, and pricing tiers, embedding `detectedChanges` in one round-trip).
