# NORTE BOUND — Data Collection & Geographic Registry Standard

This standard governs dataset curation, geographic accuracy, and anti-fabrication verification for **NORTE BOUND** across **database/seeds/** and **database/research/**.

---

## 1. Official PSA LGU Count Clarification (23 LGUs Total)

Per the **Philippine Statistics Authority (PSA)** Philippine Standard Geographic Code (PSGC) for the Province of **Ilocos Norte**:
- **2 Component Cities:** Batac City, Laoag City *(Provincial Capital)*
- **21 Municipalities:** Adams, Bacarra, Badoc, Bangui, Banna (Espiritu), Burgos, Carasi, Currimao, Dingras, Dumalneg, Marcos, Nueva Era, Pagudpud, Paoay, Pasuquin, Piddig, Pinili, San Nicolas, Sarrat, Solsona, Vintar
- **Total Official LGUs:** **23 LGUs**

> **Thesis Scope Alignment Note:** Early project summaries occasionally referred to "22 LGUs (20 municipalities + 2 component cities)". To preserve 100% geographic fidelity with PSA PSGC records and eliminate blind spots in interior/emerging towns, **all 23 official LGUs** are registered in `database/seeds/01_lgus_registry.json`.

---

## 2. The Four Tourism Circuits of Ilocos Norte

To support coherent geographic routing and prevent chaotic back-and-forth scheduling, all 23 LGUs are partitioned into four contiguous tourism circuits (`tourism_cluster`):

1. **`northern_coast`** *(6 LGUs)*: Pasuquin, Burgos, Bangui, Pagudpud, Dumalneg, Adams
   - *Profile:* Wind energy corridors, dramatic limestone cliffs, white-sand coves, Patapat Viaduct, and northern mountain waterfalls.
2. **`central_urban_heritage`** *(5 LGUs)*: Laoag City, San Nicolas, Bacarra, Sarrat, Vintar
   - *Profile:* Provincial transit and commercial hub, Spanish-era civic architecture, Burnay/Damili crafts, and nearby river-valley trails.
3. **`southern_heritage_coast`** *(5 LGUs)*: Paoay, Batac City, Currimao, Pinili, Badoc
   - *Profile:* UNESCO Earthquake Baroque heritage, sand dunes, culinary empanada hubs, Abel Iloko weaving, garlic/agro crafts, and southern surf coves.
4. **`eastern_agri_highland`** *(7 LGUs)*: Dingras, Piddig, Solsona, Carasi, Banna (Espiritu), Marcos, Nueva Era
   - *Profile:* Agricultural heartland, upland pine ridges, eco-cultural parks, waterfalls, and high-priority **tourism dispersal** destinations.

---

## 3. Data Verification & Anti-Fabrication Policy

To uphold NORTE BOUND's **Zero-Hallucination Grounding** guardrail:

1. **No LLM-Invented Records:** Google Gemini (`gemini-2.5-flash`) must **never** generate destination names, coordinates, fees, or schedules. Every destination in MySQL is curated from human-verified records.
2. **Explicit Flagging Over Guessing:** If an entrance fee, parking rate, or operating schedule cannot be confirmed from a primary source during curation, the field must retain a conservative documented placeholder or `0`/standard daytime hours **and** the record must set:
   - `"verification_status": "needs_field_verification"`
3. **Required Source Attribution:** Every destination record must cite:
   - `source_name` (e.g., Ilocos Norte Provincial Tourism Office, Municipal Tourism Office, DOT Accreditation List, or official establishment page)
   - `source_type` (`provincial_tourism` | `lgu_official` | `dot_accredited` | `verified_establishment`)
   - `last_verified_date` (`YYYY-MM-DD`)
4. **Operating Hours Array (Days `0`–`6`):** Every destination requires explicit day-of-week coverage (`0` = Sunday through `6` = Saturday) so the hard constraint filter never schedules a stop on a closed day.

---

## 4. Mathematical Role of `baseline_dispersal_bonus` and `road_tortuosity_multiplier`

### A. `baseline_dispersal_bonus` (Range: `0.00` – `1.00`)
Used inside the multi-criteria recommendation scoring formula:
$$S_{total} = w_1 S_{interest} + w_2 S_{budget} + w_3 S_{proximity} + w_4 S_{duration} + w_5 S_{dispersal}$$

- **Major Hubs (`is_major_hub: true`)** — Laoag City (`0.15`), Paoay (`0.20`), Pagudpud (`0.20`), Batac City (`0.25`), Burgos (`0.30`) — receive lower baseline bonuses because they naturally dominate tourist traffic.
- **Intermediate Coastal/Heritage LGUs** receive moderate bonuses (`0.45`–`0.70`).
- **Interior & Emerging Dispersal LGUs** (e.g., Carasi `0.98`, Dumalneg `0.96`, Adams `0.95`, Nueva Era `0.94`, Solsona `0.88`) receive high baseline bonuses (`0.75`–`1.00`) so qualified hidden gems surface competitively when aligned with user interests and travel windows.

### B. `road_tortuosity_multiplier` (Range: `1.20` – `1.60`)
Before calling external routing engines (OSRM / OpenRouteService) on the final selected sequence, the backend computes a fast all-pairs candidate distance matrix using Haversine straight-line distance $d_{\text{hav}}$ multiplied by the LGU/segment tortuosity factor $\tau$:
$$d_{\text{est}} = d_{\text{hav}} \times \tau$$

- **`flat_coastal` (`1.20`–`1.32`):** Straight national highway corridors (e.g., Laoag City `1.20`, San Nicolas `1.22`, Bacarra `1.22`).
- **`rolling_inland` (`1.25`–`1.40`):** Provincial inland roads with moderate curves (e.g., Dingras `1.32`, Piddig `1.35`, Vintar `1.40`).
- **`mountainous_winding` (`1.48`–`1.60`):** Steep switchbacks and Cordillera foothill access roads (e.g., Solsona `1.48`, Nueva Era `1.54`, Carasi `1.56`, Adams `1.58`).
