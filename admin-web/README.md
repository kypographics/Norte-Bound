# NORTE BOUND — Web Admin Portal

An isolated, responsive web-based administration portal for curators and administrators of **NORTE BOUND: Ilocos Norte Tourism Recommendation & Itinerary Planning System**.

---

## 🎨 Design System
Adheres strictly to the **Cupertino Nature-First** design system:
- **Background:** Warm Sand (`#F5E6D3`)
- **Cards & Surfaces:** Elevated Ivory Sand (`#FAF4EC`)
- **Headers & Typography:** Deep Forest Green (`#092008`)
- **CTA Actions & Accents:** Terracotta Orange (`#E27D5A`)
- **Status Badges & Pills:** Sky Blue (`#87CEEB`)

---

## 🚀 Key Features

1. **Secure Admin Authentication:**
   - Authenticates via `POST /api/v1/auth/login`.
   - Enforces RBAC: blocks non-admin users (tourist accounts) with a `403` error message.
   - Stores JWT session securely in `localStorage`.

2. **Destination Management Table:**
   - Lists seeded destinations across all 23 LGUs in Ilocos Norte.
   - Filterable by keyword, LGU, and verification status.
   - Summary metric counters for Total Destinations, Verified Records, and Hidden Gems.

3. **Quick Status Toggle:**
   - Instant patch toggle between `verified` and `needs_field_verification` via `PATCH /api/v1/admin/destinations/:id/status`.

4. **Add / Edit Destination Modal:**
   - Comprehensive form supporting all metadata fields (name, slug, LGU code, cluster, category, coordinates, entity type, popularity tier, pricing summary, highway accessibility, and tags).

5. **Delete Destination Guard:**
   - Confirms deletion before issuing `DELETE /api/v1/admin/destinations/:id`.

---

## ⚙️ How to Run

1. Start the backend server (ensure MySQL is running and migrations/seeds are applied):
   ```bash
   cd backend
   npm install
   npm run dev
   ```
2. Open `admin-web/index.html` in any modern web browser or serve it via a local static server:
   ```bash
   npx serve admin-web
   ```
3. Sign in using curator credentials:
   - **Email:** `admin@nortebound.ph`
   - **Password:** `AdminPass123!`
