# NORTE BOUND

> **An AI-Assisted Context-Aware Tourism Recommendation and Dynamic Itinerary Planning System for Ilocos Norte, Philippines**

NORTE BOUND combines deterministic multi-criteria recommendation scoring, time-window itinerary scheduling, interactive OSRM/OpenStreetMap mapping, and bounded natural-language preference extraction via Google Gemini across Ilocos Norte, Philippines.

---

## Running Locally (Active Terminals Required)

Keep **Terminal 1** active at all times because both the Flutter app and the Curator Admin Web Portal communicate with the Express API on port `5000`.

### Terminal 1 — Backend API (Required for both App & Admin Web)
Ensure `backend/.env` exists (copy from `backend/.env.example` and fill in your Supabase PostgreSQL, `JWT_SECRET`, `ADMIN_INVITE_CODE`, and `GEMINI_API_KEY` values):

```bash
cd backend
npm install   # first time only
npm run dev   # or: npm start
```

Verify the API is live before launching clients:
- Health check: `http://localhost:5000/api/v1/health`

### Terminal 2 — Curator Admin Web Portal (`admin-web/`)
Open a second terminal at the repository root and keep a static server running:

```bash
npx serve admin-web -l 5173
# Or with Python:
python -m http.server 5173 --directory admin-web
```

- Open `http://127.0.0.1:5173` and sign in with an administrator account.
- Connects to `http://localhost:5000/api/v1` by default (override anytime via `?api=https://your-api-url/api/v1`).

### Terminal 3 — Flutter App (`mobile/`)
Open a third terminal:

```bash
cd mobile
flutter pub get   # first time only

# Android Emulator (defaults to http://10.0.2.2:5000/api/v1):
flutter run

# Flutter Web in Chrome (defaults to http://localhost:5000/api/v1):
flutter run -d chrome

# Physical Android device on the same Wi-Fi/LAN or hosted backend:
flutter run --dart-define=API_BASE_URL=http://<YOUR_LAN_IP>:5000/api/v1
```

---

## Release APK & GitHub Releases

- **Local APK build:**
  ```bash
  cd mobile
  flutter build apk --release
  # Output: mobile/build/app/outputs/flutter-apk/app-release.apk
  ```
- **Automated GitHub Release APK:** Pushing any `v*` tag triggers [.github/workflows/release-apk.yml](.github/workflows/release-apk.yml) to run `flutter analyze`, `flutter test`, build the release APK, and publish it on GitHub Releases:
  ```bash
  git tag -a v0.1.1 -m "Release v0.1.1"
  git push origin v0.1.1
  ```
- For production APKs built on GitHub Actions, set `API_BASE_URL` in **GitHub Repository Settings → Secrets and variables → Actions → Variables** (otherwise Android builds default to `http://10.0.2.2:5000/api/v1`).

---

## Monorepo Structure

```text
NORTE-BOUND-NEW/
├── .github/workflows/        # Automated GitHub Release APK workflow
├── admin-web/                # Static Curator Admin Web Portal
├── backend/                  # Node.js + Express REST API
│   └── src/
│       ├── config/           # DB pool, environment config, external API clients
│       ├── controllers/      # HTTP request/response orchestration
│       ├── middlewares/      # JWT authentication, RBAC guards, Zod validation
│       ├── models/           # Parameterized Supabase PostgreSQL queries
│       ├── routes/           # Express route definitions
│       ├── schemas/          # Zod schemas (request validation & Gemini structured output)
│       ├── services/         # Recommendation engine, scheduler, Gemini service, auth
│       └── utils/            # Pure helpers (Haversine distance, time math, formatters)
├── mobile/                   # Flutter cross-platform client app
├── database/
│   ├── migrations/           # PostgreSQL DDL schema migration scripts
│   ├── seeds/                # Initial seed data for Ilocos Norte LGUs and destinations
│   └── research/             # Tourism metadata research & citation snapshots
├── docs/                     # Architecture, requirements, and API specifications
├── AGENTS.md                 # Engineering guardrails & design system
└── README.md
```

---

## Tech Stack

- **Frontend (`mobile/`):** Flutter, Riverpod (`flutter_riverpod`), `go_router`, `dio`, `flutter_map`, `latlong2`, `cached_network_image`, `geolocator`.
- **Admin Web (`admin-web/`):** Static HTML/CSS/JS following the Cupertino Nature-First design system.
- **Backend (`backend/`):** Node.js (ES Modules, `"type": "module"`), Express.js, `pg` (Supabase PostgreSQL), `zod`, `bcrypt`, `jsonwebtoken`.
- **AI Engine:** Google Gemini API (`gemini-2.5-flash`) with Structured Outputs (`responseSchema`).
- **Routing & Maps:** OpenStreetMap + OSRM road geometry (with Haversine road tortuosity matrix scoring).
- **Database (`database/`):** Supabase (PostgreSQL 17 with Row-Level Security and parameterized SQL only, no ORMs hiding queries).

---

## Development Roadmap

- **Phase 1: Foundation & Scaffolding** (Monorepo setup, architectural docs, database schema design)
- **Phase 2: Backend Core Services & PostgreSQL Integration** (Auth, LGU discovery, Gemini preference parser, recommendation engine)
- **Phase 3: Itinerary Scheduler & REST API Integration** (Time-window greedy scheduler, expense breakdown, Express endpoints)
- **Phase 4: Flutter Mobile App & Admin Web Development** (Cupertino Nature-First UI, state management, OSRM/OSM map integration, Curator Portal)
- **Phase 5: Testing, Polish & Deployment** (End-to-end verification, performance tuning, release APK automation)
