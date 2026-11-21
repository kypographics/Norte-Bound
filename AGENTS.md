# AGENTS.md — NORTE BOUND Engineering & Architecture Rules

This file defines the permanent engineering standards, architectural guardrails, and design system rules for **NORTE BOUND**. All AI agents and contributors must strictly follow these conventions across the monorepo.

---

## 1. Project Overview

**NORTE BOUND** is an AI-assisted, context-aware tourism recommendation and dynamic itinerary planning system covering all **22 Local Government Units (LGUs)** (20 municipalities and 2 component cities) of **Ilocos Norte, Philippines**.

The system combines deterministic multi-criteria recommendation scoring, time-window itinerary scheduling, and interactive mapping with bounded natural-language preference extraction via Google Gemini.

---

## 2. Tech Stack

### Frontend (`mobile/`)
- **Framework:** Flutter + Dart
- **State Management:** Riverpod (`flutter_riverpod`)
- **Routing:** `go_router`
- **Networking:** `dio`
- **Maps & Spatial:** `flutter_map` (OpenStreetMap tiles), `latlong2`

### Backend (`backend/`)
- **Runtime & Framework:** Node.js (ES Modules, `"type": "module"`) + Express.js
- **Database Driver:** `pg` (**Supabase PostgreSQL — parameterized SQL queries only**)
- **Validation:** `zod` (request payloads, environment config, and AI structured output validation)
- **Authentication & Security:** `bcrypt` (password hashing), `jsonwebtoken` (JWT RBAC sessions)

### AI Engine
- **Model:** Google Gemini API (`gemini-2.5-flash`)
- **Usage Mode:** Structured Outputs (`responseSchema`) strictly for extracting user preferences from natural language into validated JSON.

### Routing & Maps
- **Mapping & Routing:** OpenStreetMap + OSRM / OpenRouteService
- **Fast Matrix Scoring:** Haversine distance with a road tortuosity multiplier for fast candidate scoring before route refinement.

### Database (`database/`)
- **Engine:** Supabase (PostgreSQL 17)
- **Rules:** Enable Row-Level Security (RLS) on all public tables, and no ORMs that obscure SQL queries. Write explicit, clean, parameterized SQL inside `backend/src/models/`.

---

## 3. Core Architectural Guardrails

1. **Zero-Hallucination Grounding (Strict LLM Boundary):**
   - **NEVER** allow the LLM to invent destinations, GPS coordinates, entrance fees, travel times, or operating hours.
   - All factual tourism data must originate strictly from verified MySQL records.
   - Gemini is used exclusively to translate natural-language user prompts into structured preference constraints, which must pass `zod` schema validation and require explicit user confirmation before itinerary generation.

2. **Mandatory Authentication & RBAC:**
   - All core planning and curation endpoints require valid JWT authentication.
   - Enforce Role-Based Access Control (`tourist` and `admin` roles) via Express middleware (`backend/src/middlewares/`).
   - Curator CRUD operations on destinations, clusters, and verified metadata are restricted to `admin`.

3. **Backend-Centralized Business Logic:**
   - Keep **all** recommendation scoring math, hard/soft constraint filtering, budget validation, deterministic expense breakdowns, meal window injection, and time-window itinerary scheduling inside `backend/src/services/`.
   - **NEVER** duplicate scoring formulas, scheduling logic, or budget math inside the Flutter client. Flutter acts strictly as a reactive presentation and interaction layer.

4. **Clean Monorepo Separation:**
   - `backend/src/config/` — DB pool, env validation, external API clients
   - `backend/src/schemas/` — Zod schemas for HTTP requests and Gemini structured outputs
   - `backend/src/models/` — Parameterized MySQL queries only
   - `backend/src/services/` — Scoring engine, itinerary scheduler, Gemini extraction service, auth service
   - `backend/src/controllers/` — HTTP request/response orchestration
   - `backend/src/middlewares/` — JWT auth, RBAC guards, Zod validation, global error handler
   - `backend/src/routes/` — Express route definitions
   - `backend/src/utils/` — Pure helpers (Haversine, time-window math, formatters)

---

## 4. UI/UX Design System ("Cupertino Nature-First" / Apple HIG)

All Flutter UI components must adhere to the **Cupertino Nature-First** design language inspired by Apple Human Interface Guidelines:

### Color Palette
- **Primary Color — Deep Forest Green (`#092008`):**
  - Headlines, primary body text, key icons, and translucent frosted navigation/app bars (`82%` opacity + `BackdropFilter` blur).
- **Secondary / Canvas — Warm Sand Beige (`#F5E6D3`) & Elevated Ivory Sand (`#FAF4EC`):**
  - `#F5E6D3` for primary scaffold backgrounds.
  - `#FAF4EC` for elevated cards, modal sheets, and draggable bottom sheets.
- **Accent — Sky Blue (`#87CEEB`):**
  - Used exclusively as subtle badge fills (`25%` opacity) for explainability match scores and distance/time pills.
  - **Contrast Rule:** Always pair `25%` opacity Sky Blue fills with `#092008` text—**NEVER** render white text on Sky Blue.
- **Highlight / CTA — Terracotta Orange (`#E27D5A`):**
  - Primary pill CTA buttons, budget progress gauges, and active map route polylines.

### Typography
- **Font Family:** Neo-Grotesque (`Inter` / `SF Pro` / `Helvetica Neue` metrics).
- **Large Titles:** Tight negative letter-spacing (`-0.8px`) for crisp editorial hierarchy.
- **Numeric Precision:** Enforce `tabularFigures` (`FontFeature.tabularFigures()`) for all currency amounts (PHP), durations, distances, and timestamps.
- **Hierarchy:** Strict contrast between large display headers, medium section labels, and muted secondary metadata.

### Geometry & Interaction
- **Squircle Corners:** Apple-style continuous squircle corners (`ContinuousRectangleBorder` / `24px` outer card radius, with concentric inner radii on nested badges and thumbnails).
- **Borders & Surfaces:** Subtle `0.5px` hairline borders for structural separation over heavy drop shadows.
- **Sheets & Feedback:** Draggable bottom sheets over interactive `flutter_map` views and light haptic feedback (`HapticFeedback.lightImpact()`) on key interactions (filter toggles, stop swaps, itinerary confirmation).
