# NORTE BOUND: Phased Implementation Plan (Case Study Revision 3)

> **Engineering Mode:** Ponytail (smallest complete change that satisfies every Case Study Revision 3 requirement, zero speculative abstractions, reuse existing monorepo layers, and back every non-trivial engine with deterministic tests).

---

## 1. Completed Baseline (Phases 1 – 7.2)

- [x] **Phases 1–3 (Supabase PostgreSQL Database & Verified Dataset):** Migrated and deployed to **Supabase PostgreSQL 17** (`NorteBound` project `ewqohgqsuaisivvbavfy`) with Row-Level Security (RLS) enabled on all 11 tables, 69 verified destinations across all 23 LGUs (4 circuits, 6 categories, 28 interest tags, 483 7-day operating schedule slots, 69 pricing tiers, plus `recommended_duration_minutes`, `best_time_of_day`, and `is_community_based`), and idempotent runner (`database/seeds/run_migrator_and_seeds.mjs`).
- [x] **Phase 4 (Backend Foundation & Discovery/Admin APIs):** Express ESM server, `pg` Supabase connection pooler (`backend/src/config/db.mjs`), Zod validation, JWT auth + RBAC, `/api/v1/health`, `/api/v1/auth/*`, `/api/v1/destinations/*`, and `/api/v1/admin/destinations/*`.
- [x] **Phases 5–6 (Flutter Auth & Profile Defaults):** Cupertino Nature-First theme, Dio JWT interceptor, Login/Register screens, Profile screen with persisted `TravelPreferences` (`transportMode`, `budgetScope`, `groupSize`, `pacing`), and 4-tab frosted floating shell.
- [x] **Phase 7.1 (Explore, Search & Isolated Admin Web Portal):** `DiscoveryScreen`, `SearchScreen`, `LguClusterSheet`, and standalone `admin-web/` curation portal.
- [x] **Phase 7.2 (Destination Detail & Operational Verification Badges):** `DestinationDetail` model with live `operationalStatusAt`, `DestinationDetailScreen` (provenance card, itemized PHP pricing, 7-day schedule with live Open/Closed pill, frosted bottom CTA), 0 analyzer issues, and 44 passing Flutter tests.

---

## 2. Upcoming Implementation Phases (Phases 8 – 12)

### Phase 8: Database Migration `008` + Backend AI Intent Parser & Recommendation Engine
**Goal:** Satisfy Revision 3 **Sys-Obj A.2, A.4, A.5, A.8** and **RQ2, RQ4, RQ6**.

1. **Migration `008` & Seeder Update (`database/`)**
   - Create `database/migrations/008_add_visit_duration_and_community_flags.sql` adding:
     - `recommended_duration_minutes INT UNSIGNED NOT NULL DEFAULT 60`
     - `best_time_of_day VARCHAR(32) NULL`
     - `is_community_based TINYINT(1) NOT NULL DEFAULT 0`
   - Update `database/seeds/run_migrator_and_seeds.mjs` to read the existing `dest.duration_and_pacing.recommended_duration_minutes` and `dest.duration_and_pacing.best_time_of_day` already present in `03_destinations_dataset.json` (plus derive `is_community_based` from community/artisan/cooperative records), and expose them in `destination.model.mjs` and `destination.mapper.mjs`.
2. **Haversine & Tortuosity Distance/Transport Helper (`backend/src/utils/geo.matrix.mjs`)**
   - Pure helper computing distance (`km`), travel time (`minutes`), and local transport cost (`PHP`) between any two coordinates/LGUs by `transportMode` (`motorcycle`, `privateCar`, `publicCommute`) using LGU `road_tortuosity_multiplier`.
3. **AI Preference Interpretation Service (`backend/src/services/ai.intent.service.mjs` & `backend/src/schemas/recommendation.schema.mjs`)**
   - Endpoint: `POST /api/v1/recommendations/parse-intent`
   - Extract all 6 Revision 3 dimensions (`categories`, `interestTags`, `budgetAmount`/`budgetLevel`/`budgetScope`, `preferredScenery`, `preferredLgus`/`preferredClusters`, `availableDays`/`availableHoursPerDay`/`startTime`/`endTime`) via `gemini-2.5-flash` structured output (`responseSchema`) + deterministic keyword/synonym fallback.
4. **Deterministic Recommendation & $\ge 30\%$ Quota Engine (`backend/src/services/recommendation.service.mjs`)**
   - Endpoint: `POST /api/v1/recommendations`
   - Hard constraint filter: strictly `verification_status = 'verified'`, open on target day, within budget, and matching locked area.
   - 5-factor weighted scoring ($S_{\text{total}} = w_1 S_{\text{interest}} + w_2 S_{\text{budget}} + w_3 S_{\text{proximity}} + w_4 S_{\text{duration}} + w_5 S_{\text{dispersal}}$).
   - $\ge 30\%$ lesser-known (`hidden_gem`) or community-based (`is_community_based = 1`) quota selector when qualifying feasible candidates exist.
   - Explainability payload (`matchPercentage`, `scoreBreakdown`, `distanceKm`, `estimatedTravelMinutes`, `explanationReasons`) + zero-result constraint relaxation diagnostics.
5. **Phase 8 Verification Gate:**
   - Run migrator (`008` applied cleanly) and automated backend test verifying `/parse-intent` and `/recommendations` (confirming unverified stops are excluded and $\ge 30\%$ quota holds).

---

### Phase 9: Backend Time-Window Itinerary Scheduler, Feasibility Verifier & Dynamic Recalculation API
**Goal:** Satisfy Revision 3 **Sys-Obj A.6, A.7**, **RQ3, RQ5**, and **Eval-Obj B.3, B.5, B.9**.

1. **Time-Window Greedy Scheduler & 5-Condition Feasibility Verifier (`backend/src/services/itinerary.service.mjs`)**
   - Sequence selected/top-scored stops across `totalDays` within `[startTime, endTime]`.
   - Inject lunch (`11:30–13:30`) and dinner (`17:30–19:30`) meal windows using nearby verified `food_culinary` destinations or stop meal cost estimates.
   - Calculate deterministic PHP expense breakdown (`entranceAndActivityCost`, `parkingCost`, `mealsCost`, `transportCost`, `totalEstimatedCost`).
   - Run the **5-Condition Feasibility Verifier** (`timeBudgetCompliant`, `operatingHoursCompliant`, `financialBudgetCompliant`, `timeWindowCompliant`, `routesCalculable`) and populate `violatedConstraints`.
2. **Change-Detection Matrix & $< 10\text{s}$ Dynamic Recalculation (`backend/src/services/itinerary.service.mjs` & `backend/src/models/itinerary.model.mjs`)**
   - Implement `POST /api/v1/itineraries/generate` to handle both initial generation and $< 10\text{s}$ dynamic recalculation (accepting updated time/budget/origin/preferences, `lockedDestinationIds`, or `excludedDestinationIds`, and returning the schedule, `feasibilityReport`, `changeDetectionReport`, and `recalculationTimeMs`).
   - Implement saved itinerary CRUD (`POST /api/v1/itineraries`, `GET /api/v1/itineraries`, `GET /api/v1/itineraries/:id`, `DELETE /api/v1/itineraries/:id`), where `GET /api/v1/itineraries/:id` diffs saved stops against live MySQL destination `verification_status`, `temporarily_closed`, `opening_time`/`closing_time`, and `pricing_tiers` in the same query.
3. **Phase 9 Verification Gate:**
   - Automated integration test covering generation, 5-condition feasibility pass/fail diagnostics, admin closure auto-detection, and $< 10\text{s}$ recalculation speed.

---

### Phase 10: Flutter AI Co-Pilot Tab, GPS/Manual Origin & Explainable Recommendations UI
**Goal:** Satisfy Revision 3 **Steps 1–3 & 6** in the mobile client (`mobile/lib/features/preferences/`).

1. **Domain & Data Layer (`features/preferences/domain/` & `data/`)**
   - `TripPreferencesQuery`, `ParsedTripIntent`, `RecommendedStop` (with explainability reasons & score breakdown), and `RecommendationRepository`.
   - Riverpod providers managing active draft stops (connected to the **"Add to Itinerary"** button in `DestinationDetailScreen`), origin LGU / GPS coordinates, parsed intent confirmation state, and recommendations list.
2. **AI Co-Pilot & Preference Wizard Screen (`planner_screen.dart`)**
   - GPS / Manual Starting LGU selector bar.
   - Natural-language prompt input + **"Interpret with AI"** button.
   - Structured controls for Days, Daily Time Window, PHP Budget & Scope, Categories, Scenery, Circuit/LGU, Transport Mode, and Pacing.
   - **Extracted Preference Confirmation Card** allowing user review/editing of all 6 dimensions before fetching recommendations.
3. **Explainable Recommendations Section / Screen**
   - Render scored cards with `25%` Sky Blue match badges (`#092008` text), distance/time pills, *"Why Recommended"* bullets, $\ge 30\%$ hidden-gem/community inclusion summary badge, and **"Generate Feasible Itinerary"** CTA.
4. **Phase 10 Verification Gate:**
   - `flutter analyze` (0 issues) + widget tests for AI prompt confirmation flow and explainable recommendation cards.

---

### Phase 11: Flutter Feasible Itinerary Timeline, Dynamic Recalculation & Interactive OpenStreetMap View
**Goal:** Satisfy Revision 3 **Sys-Obj A.3, A.6, A.7** and **Steps 7–9** in the mobile client (`mobile/lib/features/itinerary/` & `features/map/`).

1. **Itinerary Timeline & Expense Breakdown Screen (`features/itinerary/presentation/itinerary_screen.dart`)**
   - **5-Condition Feasibility Banner** showing verified checkmarks or exact violated constraint alert.
   - **Deterministic PHP Expense Gauge** (Entrance/Activity, Meals, Transport, Remaining Budget).
   - **Day-by-Day Chronological Timeline** with arrival–departure timestamps, operating hours compliance pills, meal windows, travel leg pills, and 1-tap **Swap / Remove / Reorder** stop actions.
   - **Dynamic Adjustment & Change-Detection Sheet:** Lets user modify remaining time, budget, or current LGU, or check live admin updates and recalculate in $< 10\text{s}$ (displaying recalculation duration).
2. **Interactive Tourism Map Screen (`features/map/presentation/itinerary_map_screen.dart`)**
   - `flutter_map` with OpenStreetMap tiles, numbered itinerary stop markers, user GPS/origin marker, **Terracotta (`#E27D5A`) route polylines** between consecutive stops (OSRM with tortuosity-geodesic fallback), and draggable bottom leg summary sheet.
3. **Router Wiring (`mobile/lib/core/router/app_router.dart`)**
   - Wire itinerary timeline and interactive map routes from the AI Co-Pilot tab and Destination Detail CTA.
4. **Phase 11 Verification Gate:**
   - `flutter analyze` (0 issues) + widget tests for Itinerary Timeline, 5-Condition Feasibility Banner, Dynamic Recalculation flow, and Map view.

---

### Phase 12: Case Study Revision 3 Evaluation Benchmark Suite & Final Polish
**Goal:** Quantitatively prove all **Research-Evaluation Objectives (B.1–B.9)** for the capstone manuscript and defense.

1. **Automated Evaluation Benchmark (`backend/tests/evaluate_case_study_metrics.mjs`)**
   - **Eval-Obj B.2 (AI Extraction Accuracy):** Run 50 held-out natural-language requests and assert $\ge 85\%$ exact match across all 6 preference dimensions.
   - **Eval-Obj B.3 (Feasibility Compliance):** Verify 100% accuracy of the 5-condition feasibility checker across feasible and intentionally constrained test scenarios.
   - **Eval-Obj B.5 (Recalculation Speed):** Benchmark all user and admin change types on 10-stop itineraries and assert $< 10\text{ seconds}$ (target $< 200\text{ms}$ server-side).
   - **Eval-Obj B.6 (Lesser-Known / Community Quota):** Verify $\ge 30\%$ inclusion across diverse tourist profiles without violating feasibility.
   - **Eval-Obj B.9 (Change-Detection Matrix):** Verify automatic detection of admin destination closures, schedule shifts, and price updates vs. manual user preference edits.
2. **Full Monorepo Regression Check**
   - Run backend benchmark suite + `flutter analyze` (0 issues) + `flutter test` (100% green).
