# NORTE BOUND: Requirements and Architecture Documentation

## 1. System Overview
**NORTE BOUND** is an AI-assisted, context-aware tourism recommendation and dynamic itinerary planning system covering all **22 Local Government Units (LGUs)** (20 municipalities and 2 component cities: Laoag City and Batac City) of **Ilocos Norte, Philippines**.

---

## 2. Functional Requirements

### FR-AUTH: Mandatory Authentication & Role-Based Access Control (RBAC)
- **FR-AUTH-01:** Users must register and authenticate via JWT-based sessions with hashed passwords (`bcrypt`).
- **FR-AUTH-02:** System enforces RBAC distinguishing between `tourist` (standard user for discovery, preferences, recommendation, and itinerary generation) and `admin` (curator role for verified metadata management).
- **FR-AUTH-03:** All protected API endpoints must validate incoming JWT bearer tokens via Express middleware.

### FR-DISC: 22 LGUs & Tourism Clusters Discovery
- **FR-DISC-01:** The system shall provide structured browsing and spatial filtering across all 22 LGUs of Ilocos Norte.
- **FR-DISC-02:** Destinations shall be categorized into verified tourism clusters (e.g., Heritage & History, Eco-Adventure, Coastal & Beaches, Culinary & Agritourism, Religious & Cultural).
- **FR-DISC-03:** Each destination record must contain verified metadata (GPS coordinates, operating hours, entrance fees, contact info, official descriptions, and photo references).

### FR-PREF: Structured & Gemini Natural Language Preference Extraction
- **FR-PREF-01:** Users can input natural-language trip descriptions (e.g., *"We want a 3-day family cultural trip around Laoag and Pagudpud with a moderate budget focusing on beaches and local cuisine"*).
- **FR-PREF-02:** The Google Gemini API (`gemini-2.5-flash`) processes raw text prompts using Structured Outputs (`responseSchema`) to extract verified constraints into validated JSON (travel dates, party size, budget tier, preferred LGU/clusters, dietary restrictions).
- **FR-PREF-03:** Extracted preferences must undergo strict `zod` schema validation and require explicit user review and confirmation before recommendation scoring or itinerary scheduling.

### FR-REC: Recommendation Engine & Scoring
- **FR-REC-01:** Hard constraints (budget cap, operating hours, mobility/accessibility needs, LGU availability) filter out non-viable candidate destinations.
- **FR-REC-02:** Surviving candidates are evaluated using a multi-criteria weighted scoring formula:
  $$S_{total} = w_1 S_{interest} + w_2 S_{budget} + w_3 S_{proximity} + w_4 S_{duration} + w_5 S_{dispersal}$$
  Where weights $w_1$ through $w_5$ reflect user preference profiles.
- **FR-REC-03:** The recommendation payload includes clear explainability badges (e.g., match score breakdown, distance/time pills).
- **FR-REC-04:** If hard constraints yield zero results, the system triggers a constraint relaxation diagnostic and suggests actionable adjustments (e.g., increasing budget by 15% or expanding search radius).

### FR-ITIN: Dynamic Itinerary Planning & Scheduling
- **FR-ITIN-01:** A time-window greedy scheduler constructs chronological day-by-day itineraries respecting operating hours and travel durations calculated via OSRM / Haversine road tortuosity matrix.
- **FR-ITIN-02:** The scheduler automatically injects mandatory meal windows (lunch and dinner) near scheduled stops based on local culinary partner database records.
- **FR-ITIN-03:** Itinerary generation calculates a deterministic expense breakdown (entrance fees, estimated meal costs, transport estimates, and total budget utilization).
- **FR-ITIN-04:** Users can interactively modify itineraries (swapping stops, reordering activities, or replacing recommendations) with automatic recalculation of travel times and budget totals.

### FR-ADMIN: In-App RBAC Curator CRUD
- **FR-ADMIN-01:** Authenticated `admin` users can perform Create, Read, Update, and Delete operations on destination metadata, LGU summaries, and tourism cluster mappings directly through secure backend endpoints.

---

## 3. Non-Functional Requirements (ISO/IEC 25010)

- **Performance & Efficiency:** API response times for candidate filtering and scoring under 500ms; map rendering and UI transitions at steady 60 FPS via Flutter.
- **Reliability & Zero-Hallucination:** 100% factual grounding. LLM is strictly constrained to JSON parsing; zero generation of invented destinations, fees, or operating hours.
- **Security & Data Protection:** Password hashing with `bcrypt`, stateless JWT authentication, parameterized SQL queries (`mysql2/promise`) preventing SQL injection, and strict input validation via `zod`.
- **Maintainability & Portability:** Strict monorepo modularity separating backend services, models, schemas, and controllers from the Flutter presentation layer.

---

## 4. Explicit System Scope & Limitations

1. **No Live Booking/Payment Gateway:** NORTE BOUND is a recommendation and itinerary planning system. It does not process financial transactions, ticket purchases, or hotel bookings.
2. **No Real-Time Telemetry:** Traffic congestion and weather conditions rely on static time-multiplier buffers rather than live telemetry feeds.
3. **Public Commute & Transport:** Travel times for public commute incorporate conservative time-multiplier buffers alongside private vehicle routing estimates.
4. **Verified Static Snapshots:** All geographical, historical, and pricing data represent verified static snapshots curated from municipal tourism offices with source citations.
