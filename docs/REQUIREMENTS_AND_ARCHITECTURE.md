# NORTE BOUND — Requirements & System Architecture

## 1. System Overview

**NORTE BOUND** is an AI-assisted, context-aware tourism recommendation and dynamic itinerary planning system designed for **Ilocos Norte, Philippines**, covering all **22 Local Government Units (LGUs)** (20 municipalities and 2 component cities: Laoag City and Batac City).

The architecture enforces strict separation between **AI-powered intent extraction** and **deterministic backend planning**: Google Gemini (`gemini-2.5-flash`) extracts structured preferences from natural language, while a MySQL-backed Node.js service layer executes verified filtering, multi-criteria weighted scoring, and time-window itinerary scheduling.

---

## 2. Functional Requirements

### `FR-AUTH` — Mandatory Authentication & RBAC
- Users must authenticate before accessing personalized recommendation, itinerary planning, saving, or curation features.
- Supports registration and login using `bcrypt`-hashed credentials and signed JWT tokens.
- Implements Role-Based Access Control (RBAC) with two roles:
  - `tourist`: Can browse destinations, extract/confirm preferences, generate/save itineraries, and swap stops.
  - `admin`: Retains full curator privileges over verified tourism records via protected administrative endpoints.

### `FR-DISC` — 22 LGUs & Tourism Clusters Discovery
- Provides structured discovery across all **22 LGUs** of Ilocos Norte, organized by geographic/thematic tourism clusters (e.g., Central Heritage & Urban, Northern Coastal & Wind Farms, Southern Eco-Cultural, Eastern Mountain & Adventure).
- Displays verified destination profiles including categories, LGU assignment, coordinates, entrance/activity fees, recommended dwell time, operating hours, and data verification citations.
- Supports cluster, LGU, category, and budget-tier filtering.

### `FR-PREF` — Structured & Gemini Natural-Language Preference Extraction
- Supports dual input modes:
  1. **Structured Form Controls:** Explicit selection of trip dates/duration, starting LGU/origin, budget ceiling (PHP), group type, transport mode (`private_vehicle` or `public_commute`), pace, and interest categories.
  2. **Natural-Language Prompt (Gemini AI):** Users describe their ideal trip in free text; `gemini-2.5-flash` with `responseSchema` converts the prompt into a strict `zod`-validated JSON preference payload.
- **Mandatory Confirmation Step:** Extracted AI preferences are never sent straight into final scheduling without user review. The client renders the extracted structured parameters for explicit user confirmation or adjustment before invoking the recommendation engine.

### `FR-REC` — Context-Aware Recommendation Engine & Explainability
- **Stage 1: Hard Constraint Filter**
  - Excludes destinations that violate non-negotiable constraints (e.g., closed on target travel day, exceeds remaining budget envelope, incompatible accessibility/category exclusions, or unreachable within available trip window).
- **Stage 2: Multi-Criteria Weighted Scoring**
  - Evaluates surviving candidates using a normalized composite score:
    $$S_{total} = w_1 S_{interest} + w_2 S_{budget} + w_3 S_{proximity} + w_4 S_{duration} + w_5 S_{dispersal}$$
    - $S_{interest}$: Alignment between destination tags/categories and user interest weights.
    - $S_{budget}$: Fee affordability relative to allocated per-stop/per-day budget.
    - $S_{proximity}$: Travel efficiency computed via Haversine distance with a road tortuosity multiplier (refined by OSRM/OpenRouteService for final routes).
    - $S_{duration}$: Compatibility between destination recommended dwell time and trip pace/available window.
    - $S_{dispersal}$: Spatial/LGU dispersal factor promoting balanced discovery across Ilocos Norte's 22 LGUs rather than over-concentrating on a single hotspot.
- **Explainability Payload:**
  - Every recommended destination returns human-readable match reasons and normalized sub-score breakdowns (rendered as Sky Blue `25%` opacity pills in the UI) explaining *why* it was selected.
- **Constraint Relaxation Diagnostic:**
  - If hard filters yield zero or insufficient destinations, the engine executes a structured diagnostic identifying which constraint(s) caused the bottleneck (e.g., strict budget cap, narrow time window, or isolated LGU filter) and proposes actionable relaxation options without fabricating data.

### `FR-ITIN` — Dynamic Time-Window Itinerary Scheduler
- **Time-Window Greedy Scheduler:**
  - Sequences top-scored candidates across multi-day or single-day windows, validating arrival times, opening/closing hours, dwell times, and inter-stop transit durations.
- **Meal Window Injection:**
  - Automatically reserves realistic lunch and dinner windows within the daily timeline, pairing nearby dining slots or budget allowances without displacing attraction operating hours.
- **Deterministic Expense Breakdown:**
  - Computes itemized cost estimates directly in the backend (entrance/environmental fees, estimated activity fees, transport fuel/commute estimates, and meal allowances) validated against the user's stated budget.
- **Interactive Stop Swapping:**
  - Users can swap any scheduled stop with ranked alternatives from the candidate pool; the backend re-runs time-window, travel-time, and budget validation on the updated sequence.

### `FR-ADMIN` — In-App RBAC Curator CRUD
- Restricted to `admin` users via JWT + RBAC middleware.
- Enables creating, updating, archiving, and verifying LGU metadata, destination records, coordinates, entrance fees, operating hours, and source attribution URLs/notes in MySQL.

---

## 3. Non-Functional Requirements (ISO/IEC 25010)

| Quality Characteristic | System Implementation & Target |
| :--- | :--- |
| **Performance Efficiency** | Indexed MySQL 8.x spatial/LGU queries; fast Haversine + tortuosity distance matrix for candidate scoring prior to OSRM/ORS polyline routing; target API recommendation latency < 1.5s (excluding optional Gemini NL call). |
| **Reliability & Zero-Hallucination** | Strict separation between LLM preference parsing and verified SQL data; `zod` validation at both HTTP ingress and Gemini JSON egress; deterministic financial and temporal calculations. |
| **Security** | `bcrypt` password hashing, signed JWT authentication, strict RBAC middleware (`tourist` vs `admin`), parameterized `mysql2/promise` queries (SQLi prevention), and isolated `.env` secrets. |
| **Maintainability** | Modular layered backend (`routes -> middlewares -> controllers -> services -> models`), centralized scoring/scheduling logic in Node.js, and Riverpod reactive state separation in Flutter. |
| **Usability & Accessibility** | Cupertino Nature-First Apple HIG design system; high-contrast accessible badges (`#092008` text on `25%` `#87CEEB` fill); transparent AI confirmation and explainable score breakdowns. |

---

## 4. Explicit System Scope & Limitations

1. **No Live Booking or Payment Processing:** NORTE BOUND is an intelligent planning and decision-support tool; it does not process hotel reservations, ticket purchases, or online payments.
2. **No Real-Time Traffic or Weather Telemetry:** Route durations rely on OSRM / OpenRouteService road network baselines and Haversine tortuosity approximations rather than live congestion feeds or real-time storm alerts.
3. **Public Commute Modeling:** Public transportation legs are modeled deterministically using road distance combined with explicit wait/transfer time-multiplier buffers rather than live GTFS transit tracking.
4. **Verified Static Data Snapshots:** Destination fees, operating hours, and schedules are maintained as curated static snapshots in MySQL with explicit source citations and verification timestamps managed by system administrators.
