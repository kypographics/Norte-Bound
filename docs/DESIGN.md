# NORTE BOUND: UI/UX Design Specification ("Cupertino Nature-First")

## 1. Design Language & Core Tokens

NORTE BOUND follows the **Cupertino Nature-First** design system inspired by Apple Human Interface Guidelines (HIG), pairing editorial clarity with high-contrast field readability for travelers across Ilocos Norte.

### A. Color Palette (`mobile/lib/core/theme/app_colors.dart`)

| Token | Hex / Value | Usage |
| :--- | :--- | :--- |
| **Deep Forest Green** (`deepForest`) | `#092008` | Primary headlines, body ink, key icons, and translucent frosted bars (`82%` opacity + `BackdropFilter` blur). |
| **Warm Sand Beige** (`warmSand`) | `#F5E6D3` | Primary scaffold background canvas. |
| **Elevated Ivory Sand** (`ivorySand`) | `#FAF4EC` | Elevated squircle cards, modal sheets, and draggable bottom sheets. |
| **Sky Blue Wash** (`skyBlueWash`) | `#87CEEB` (`25%` alpha) | Explainability match badges (`94% MATCH`), distance/time pills, and verified badges. **Contrast Rule:** Always pair with `#092008` text—never white text on Sky Blue. |
| **Terracotta Orange** (`terracotta`) | `#E27D5A` | Primary pill CTA buttons, budget progress gauges, hidden-gem accents, and active map route polylines. |
| **Muted Forest** (`mutedForest`) | `#5C6657` | Secondary descriptions, subtitles, and metadata labels. |
| **Hairline Border** (`hairline`) | `#14092008` (`0.5px`) | Structural card and divider borders replacing heavy drop shadows. |

### B. Typography & Numeric Precision (`mobile/lib/core/theme/app_typography.dart`)
- **Font Family:** `Inter` (`SF Pro` / `Helvetica Neue` metrics).
- **Editorial Display Headers:** Tight negative letter-spacing (`-0.8px`) with bold `FontWeight.w700`–`w800`.
- **Tabular Numerals (`FontFeature.tabularFigures()`):** Mandatory on all PHP currency values (`₱1,250`), match percentages (`94%`), distances (`14.2 km`), durations (`45 mins`), and operating/schedule timestamps (`08:30 – 10:00`).

### C. Geometry, Surfaces & Interaction
- **Continuous Squircles:** `ContinuousRectangleBorder` with `24px` outer radius on `AppCard` surfaces and concentric `12px–20px` inner radii on nested thumbnails, pills, and buttons.
- **Frosted Glass Chrome:** Floating 4-tab bottom shell (`Explore`, `Search`, `AI Co-Pilot`, `Profile`) and sticky bottom action bars use `ClipRect` + `BackdropFilter(sigmaX: 16, sigmaY: 16)`.
- **Tactile Feedback:** `HapticFeedback.lightImpact()` on filter toggles, preference confirmation, stop swaps, and itinerary generation.

---

## 2. Screen-by-Screen UI Specification

### 1. Explore & Search Screens (`features/discovery/presentation/screens/`) — *Completed (Phase 7.1)*
- **Explore (`discovery_screen.dart`):** Editorial hero header, 4 Tourism Circuit filter cards, Iconic Highlights carousel, Hidden Gems dispersal showcase, Culinary stops, and 23-LGU directory sheet (`lgu_cluster_sheet.dart`).
- **Search (`search_screen.dart`):** Debounced search bar, multi-filter chips (`Hidden Gems`, `Free Entry`, Category, LGU/Circuit), and paginated destination tiles.

### 2. Destination Detail Screen (`destination_detail_screen.dart`) — *Completed (Phase 7.2)*
- **Editorial Hero & Wrapped Pills:** Artwork header + wrapped pills for `LGU`, `Category`, `Popularity Tier` (`HIDDEN GEM` in terracotta wash vs. `ICONIC HUB` in sky blue wash), and `VERIFIED` status.
- **Verified Source Attribution Card:** Displays `Verification Status`, `Source Name`, `Source Type`, and `Last Verified` date to prove zero-hallucination provenance.
- **Itemized Financial Breakdown Card:** Tabular PHP breakdown for `Adult Entrance Fee`, `Student / Senior Concession`, `Mandatory Activity / Guide Fee`, `Parking Fee`, `Estimated Meal Range`, and road access summary.
- **7-Day Operating Schedule Card:** Live `OPEN NOW` / `CLOSED` badge (`operationalStatusAt`) shown only when `verification_status == 'verified'` (records marked `needs_field_verification` show `FIELD CHECK PENDING` instead of an assumed open-now claim) + 7-day tabular hours with today's row highlighted in `skyBlueWash`.
- **Sticky Frosted Bottom Bar:** Shows entry estimate and **"Add to Itinerary"** CTA.

### 3. AI Co-Pilot & Inline Recommendations Screen (`features/preferences/presentation/planner_screen.dart`) — *Phase 10*
> **Taste & Ponytail Rule (One Cohesive Flow, Plain Verb+Object Copy):** Keep input, confirmation, and scored recommendations in one progressive scroll on `/planner` rather than bouncing across separate wizard pages. Every button is a clear verb + object (1–4 words); every card holds one concrete fact line and at most two plain reason pills.

- **GPS & Manual Origin Bar (SWOT Rec #10):**
  - Displays current origin context: *"Starting from Laoag City"* with a 1-tap **"Change town"** picker so tourists with weak GPS or planning remotely can anchor distances to any of the 23 LGUs.
- **Natural-Language Trip Prompt Card:**
  - Multi-line input with example prompt chips (*"2-day coastal & heritage trip near Pagudpud under ₱2,500 with hidden waterfalls"*) and a Terracotta **"Extract trip details"** CTA (`POST /api/v1/recommendations/parse-intent`).
- **Structured Preference Controls:**
  - **Time Window:** Days stepper (`1–5 days`), daily hours/window (`08:00 – 18:00`).
  - **Budget:** `₱ PHP` budget slider/input + `Per person` / `Total group` toggle + `Group size` stepper.
  - **Interests & Scenery:** Category chips, Scenery chips (`Coastal`, `Highland`, `Heritage`, `Rural`), and Circuit/LGU selector.
  - **Transport & Pacing:** `Motorcycle` / `Private car` / `Public commute` and `Relaxed` / `Moderate` / `Packed` (initialized from saved profile defaults).
- **Extracted Preference Confirmation Card (Zero-Hallucination Gate):**
  - Displays the 6 AI-extracted dimensions (`Destination Type`, `Activity Tags`, `Budget Level`, `Preferred Scenery`, `Preferred Area`, `Available Time`) as editable pills.
  - Primary CTA: **"Find matching places"**.
- **Inline Explainable Recommendations Section:**
  - **Dispersal Summary Line:** Plain human copy with real counts: *"3 of 8 suggested stops are community or lesser-known places (38%)."*
  - **Recommendation Card (Strict Word Budget — <25 words per card):**
    - **Top Row:** `LGU · Category` + `94% match` pill (`skyBlueWash` + `#092008` tabular text) + `Hidden gem` pill when applicable.
    - **Title & Fact Line:** Destination name + one tabular fact line (`₱50 entry · 21 mins away · ~90 mins visit`).
    - **2 Plain Reason Pills:** e.g. `Open 08:00–17:00`, `Community waterfall in Adams`.
  - **Zero-Result Constraint Relaxation Card (`FR-REC-04`):**
    - Names the exact blocking limit in plain English (*"No verified stops open between 18:00 and 21:00 under ₱100"*) with 1-tap fixes (**"Raise budget by ₱200"**, **"Include nearby towns"**).
  - **Sticky Bottom Action:** **"Build itinerary"** (`POST /api/v1/itineraries/generate`).

### 4. Feasible Itinerary Timeline & Dynamic Adjustment Screen (`features/itinerary/presentation/itinerary_screen.dart`) — *Phase 11*
- **5-Condition Feasibility Banner:**
  - Plain status line: **"Feasible plan · 5 of 5 checks passed"** (Time, Opening hours, Budget, Daily window, Road route). If an edit or admin change violates a limit, shows a Terracotta alert naming the exact conflict (*"Paoay Church closes at 17:00, before your 17:30 arrival"*) with a 1-tap **"Recalculate plan"** button.
- **Deterministic Budget & Expense Breakdown Card:**
  - Terracotta progress gauge (`₱1,840 of ₱2,500 budget`) + 4 tabular rows:
    1. `Entrance & activity fees`
    2. `Estimated meals`
    3. `Local transport`
    4. `Remaining budget`
- **Day-by-Day Chronological Timeline:**
  - Day selector pills (`Day 1`, `Day 2`, ...).
  - **Scheduled Stop Cards:** Tabular time slot (`08:30 – 10:00`), destination name, LGU, opening window (`Open 08:00–17:00`), entry cost, and compact actions (**Swap stop**, **Remove**, **Move up/down**).
  - **Injected Meal Window Cards:** Culinary slot (`12:00 – 13:00 · Lunch stop`) paired with a nearby verified `food_culinary` destination or tabular meal estimate.
  - **Travel Leg Connectors:** Vertical connector line showing `11.2 km · 18 mins · ₱45 ride est.`.
- **Context Monitor & Dynamic Adjustment Sheet ("Adjust plan"):**
  - Lets the traveler update remaining time, budget, or current town, or tap **"Check live schedule changes"** to detect admin closures/hour shifts and recalculate in $< 10\text{s}$ (showing `Updated in 48 ms`).

### 5. Interactive OpenStreetMap Route Screen (`features/map/presentation/itinerary_map_screen.dart`) — *Phase 11*
- **`flutter_map` Canvas (OpenStreetMap Tiles):**
  - Numbered Deep Forest / Terracotta markers (`1`, `2`, `3`...) for itinerary stops, category pins for nearby verified sites, and an origin marker for user GPS / starting town.
  - **Terracotta Route Polyline (`#E27D5A`, `4px` stroke):** Connects consecutive itinerary stops using OSRM road geometry (with offline tortuosity-adjusted geodesic fallback).
- **Draggable Cupertino Bottom Sheet:**
  - Leg-by-leg distance and travel time summary; tapping any pin centers the map and highlights that stop.

### 6. Isolated Web Admin Portal (`admin-web/`) — *Completed (Phase 7.1)*
- Standalone HTML/CSS/JS curator dashboard connected to `/api/v1/admin/destinations` for creating, editing, and toggling `verification_status` (`verified`, `needs_field_verification`) and `temporarily_closed` flags.
