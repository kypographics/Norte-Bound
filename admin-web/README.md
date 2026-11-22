# NORTE BOUND — Curator Admin Portal

Static, zero-bundler administration web portal for curators and administrators of **NORTE BOUND: Ilocos Norte Tourism Recommendation & Itinerary Planning System**.

## Design System
Follows the **Cupertino Nature-First** specification:
- **Canvas:** Warm Sand (`#F5E6D3`)
- **Cards & Modals:** Elevated Ivory Sand (`#FAF4EC`)
- **Primary Ink & Frosted Header:** Deep Forest Green (`#092008`)
- **Category Pills:** 25% Sky Blue (`#87CEEB`) paired strictly with `#092008` text
- **Primary Actions & Dispersal Highlight:** Terracotta Orange (`#E27D5A`)
- **Numeric Precision:** `Inter` with `tabular-nums` for PHP fees, coordinates, KPI counts, and hours

## Capabilities
1. **RBAC Curator Authentication (`POST /api/v1/auth/login`):**
   - Enforces `role === 'admin'` before unlocking the dashboard.
2. **Province-Wide Registry & Live Filtering:**
   - Displays all curated destinations across all 23 Ilocos Norte LGUs (`Table` and `Photo Grid` views) with instant search, Cluster, LGU, Category, and Verification Status filters.
   - Summary KPIs track Total Places, Verified count, Pending Check count, Hidden Gem dispersal percentage (`>=30%` target), and LGU coverage.
3. **1-Tap Verification Toggle (`PATCH /api/v1/admin/destinations/:id/status`):**
   - Toggles destinations between `verified` and `needs_field_verification`.
4. **Full Curator Editor (`POST / PUT /api/v1/admin/destinations`):**
   - Edits destination photos (`image_url` with live preview), road access, verified PHP pricing, provenance metadata, interest tags, and 7-day operating hours including temporary closure controls.
5. **Protected Delete Guard (`DELETE /api/v1/admin/destinations/:id`):**
   - Custom confirmation dialog before removing unreferenced records.

## Running Locally
1. Ensure the backend API is running on `http://localhost:5000/api/v1`:
   ```bash
   cd backend
   npm run dev
   ```
2. Serve `admin-web/` over HTTP:
   ```bash
   npx serve admin-web -l 5173
   ```
   Or with Python:
   ```bash
   python -m http.server 5173 --directory admin-web
   ```
3. Open `http://localhost:5173` and sign in with an administrator account. You can override the API base URL if needed via `?api=http://localhost:5000/api/v1`.
