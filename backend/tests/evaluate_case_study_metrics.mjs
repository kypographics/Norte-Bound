/**
 * NORTE BOUND — Case Study Revision 3 Backend Evaluation Suite
 * Covers:
 *   - Eval-Obj B.2: >= 85% AI preference extraction accuracy across 50 prompts
 *   - Eval-Obj B.3: 5-condition feasibility verification & constraint violation ID
 *   - Eval-Obj B.5: < 10s dynamic recalculation speed for <= 10 stops
 *   - Eval-Obj B.6: >= 30% lesser-known / community-based inclusion ratio
 *   - Eval-Obj B.9: Change-Detection Matrix (automatic vs. manual changes)
 */

import assert from 'node:assert/strict';
import { closePool } from '../src/config/db.mjs';
import { parseNaturalLanguageIntent } from '../src/services/ai.intent.service.mjs';
import { getRecommendations } from '../src/services/recommendation.service.mjs';
import {
  detectSavedItineraryChanges,
  generateFeasibleItinerary,
} from '../src/services/itinerary.service.mjs';

const NLP_TEST_SET = [
  ['1-day beach trip in Pagudpud under 1000 php', { cat: 'natural_attraction', lgu: 'pagudpud', budget: 'budget', days: 1, scenery: 'coastal' }],
  ['2-day heritage church tour in Paoay with moderate budget', { cat: 'heritage_cultural', lgu: 'paoay', budget: 'moderate', days: 2, scenery: 'heritage_urban' }],
  ['Waterfall trekking in Adams for 1 day under 800 pesos', { cat: 'natural_attraction', lgu: 'adams', budget: 'budget', days: 1, scenery: 'highland' }],
  ['3-day luxury coastal resort and lighthouse tour in Burgos', { cat: 'natural_attraction', lgu: 'burgos', budget: 'flexible', days: 3, scenery: 'coastal' }],
  ['Food trip for empanada in Batac for 1 day budget friendly', { cat: 'food_culinary', lgu: 'batac-city', budget: 'budget', days: 1 }],
  ['2-day pottery and weaving workshop in San Nicolas and Paoay', { cat: 'artisan_craft_experience', lgu: 'san-nicolas', days: 2, scenery: 'rural_agro' }],
  ['Half-day museum and historic landmarks in Laoag under 500', { cat: 'heritage_cultural', lgu: 'laoag-city', budget: 'budget', days: 1, hours: 4 }],
  ['Weekend agro farm and windmill visit in Bangui', { cat: 'agro_eco_tourism', lgu: 'bangui', days: 2 }],
  ['1-day salt making craft tour in Pasuquin for 1200 php', { cat: 'artisan_craft_experience', lgu: 'pasuquin', budget: 'moderate', days: 1, scenery: 'rural_agro' }],
  ['4x4 sandboarding adventure in Laoag sand dunes under 3000', { cat: 'recreation_adventure', lgu: 'laoag-city', budget: 'moderate', days: 1 }],
  ['2-day mountain ridge hike in Solsona with eco-park', { cat: 'agro_eco_tourism', lgu: 'solsona', days: 2, scenery: 'highland' }],
  ['1-day church and bell tower walk in Bacarra under 600', { cat: 'heritage_cultural', lgu: 'bacarra', budget: 'budget', days: 1, scenery: 'heritage_urban' }],
  ['3-day beach cove and surfing in Currimao with 6000 budget', { cat: 'natural_attraction', lgu: 'currimao', budget: 'flexible', days: 3, scenery: 'coastal' }],
  ['Local coffee and restaurant crawl in Laoag for 1 day', { cat: 'food_culinary', lgu: 'laoag-city', days: 1 }],
  ['1-day river and eco-farm visit in Dingras under 900', { cat: 'agro_eco_tourism', lgu: 'dingras', budget: 'budget', days: 1, scenery: 'rural_agro' }],
  ['2-day weaving and garlic farm culture in Pinili', { cat: 'artisan_craft_experience', lgu: 'pinili', days: 2 }],
  ['1-day sunset beach and cliff view in Badoc under 1000', { cat: 'natural_attraction', lgu: 'badoc', budget: 'budget', days: 1, scenery: 'coastal' }],
  ['2-day highland waterfall adventure in Nueva Era', { cat: 'natural_attraction', lgu: 'nueva-era', days: 2, scenery: 'highland' }],
  ['1-day historic plaza and ancestral church in Sarrat', { cat: 'heritage_cultural', lgu: 'sarrat', days: 1, scenery: 'heritage_urban' }],
  ['Weekend forest and eco camp in Carasi under 1500', { cat: 'agro_eco_tourism', lgu: 'carasi', budget: 'moderate', days: 2, scenery: 'highland' }],
  ['1-day river dam and mountain park in Vintar under 700', { cat: 'natural_attraction', lgu: 'vintar', budget: 'budget', days: 1, scenery: 'highland' }],
  ['2-day agri-tourism coffee farm tour in Piddig', { cat: 'agro_eco_tourism', lgu: 'piddig', days: 2, scenery: 'rural_agro' }],
  ['1-day countryside eco trail in Banna under 800', { cat: 'agro_eco_tourism', lgu: 'banna', budget: 'budget', days: 1 }],
  ['1-day peaceful waterfalls and ridge walk in Dumalneg', { cat: 'natural_attraction', lgu: 'dumalneg', days: 1, scenery: 'highland' }],
  ['2-day historic museum and park visit in Marcos under 1000', { cat: 'heritage_cultural', lgu: 'marcos', budget: 'budget', days: 2 }],
  ['4-day northern coast beaches and windmills tour with 5000 php', { cat: 'natural_attraction', cluster: 'northern_coast', budget: 'flexible', days: 4, scenery: 'coastal' }],
  ['2-day eastern highland waterfalls and farms under 2000', { cat: 'natural_attraction', cluster: 'eastern_agri_highland', budget: 'moderate', days: 2, scenery: 'highland' }],
  ['1-day southern coast churches and dunes under 1500', { cat: 'heritage_cultural', cluster: 'southern_heritage_coast', budget: 'moderate', days: 1 }],
  ['1-day central urban heritage walk in Laoag under 500', { cat: 'heritage_cultural', cluster: 'central_urban_heritage', budget: 'budget', days: 1 }],
  ['3-day Pagudpud white sand beach and trekking for 2 pax', { cat: 'natural_attraction', lgu: 'pagudpud', days: 3, scenery: 'coastal' }],
  ['1-day Batac culinary empanada and miki lunch under 600', { cat: 'food_culinary', lgu: 'batac-city', budget: 'budget', days: 1 }],
  ['2-day Paoay sunset dunes and heritage church under 3000', { cat: 'heritage_cultural', lgu: 'paoay', budget: 'moderate', days: 2 }],
  ['1-day San Nicolas pottery and local dining for 1000', { cat: 'artisan_craft_experience', lgu: 'san-nicolas', budget: 'budget', days: 1 }],
  ['2-day Bangui wind farm and coastal sunset under 2500', { cat: 'agro_eco_tourism', lgu: 'bangui', budget: 'moderate', days: 2, scenery: 'coastal' }],
  ['1-day Burgos lighthouse and rock cliffs under 900', { cat: 'natural_attraction', lgu: 'burgos', budget: 'budget', days: 1, scenery: 'coastal' }],
  ['3-day Adams waterfall and mountain trek budget trip', { cat: 'natural_attraction', lgu: 'adams', budget: 'budget', days: 3, scenery: 'highland' }],
  ['1-day Badoc island cove and historic church under 1200', { cat: 'heritage_cultural', lgu: 'badoc', budget: 'moderate', days: 1 }],
  ['2-day Currimao beach resort and snorkeling adventure with 5500', { cat: 'natural_attraction', lgu: 'currimao', budget: 'flexible', days: 2, scenery: 'coastal' }],
  ['1-day Pasuquin soft biscocho bakery food stop under 500', { cat: 'food_culinary', lgu: 'pasuquin', budget: 'budget', days: 1 }],
  ['2-day Vintar hiking trail and river camp under 1500', { cat: 'recreation_adventure', lgu: 'vintar', budget: 'moderate', days: 2, scenery: 'highland' }],
  ['1-day Sarrat museum and river bridge heritage tour', { cat: 'heritage_cultural', lgu: 'sarrat', days: 1, scenery: 'heritage_urban' }],
  ['1-day Bacarra historic tower and miki eatery under 700', { cat: 'food_culinary', lgu: 'bacarra', budget: 'budget', days: 1 }],
  ['2-day Solsona mountain pine ridge adventure for 3000', { cat: 'recreation_adventure', lgu: 'solsona', budget: 'moderate', days: 2, scenery: 'highland' }],
  ['1-day Piddig coffee farm and rice terrace under 1000', { cat: 'agro_eco_tourism', lgu: 'piddig', budget: 'budget', days: 1, scenery: 'rural_agro' }],
  ['1-day Dingras heritage church and farm lunch under 800', { cat: 'heritage_cultural', lgu: 'dingras', budget: 'budget', days: 1 }],
  ['2-day Pinili artisan weaving loom and museum tour', { cat: 'artisan_craft_experience', lgu: 'pinili', days: 2 }],
  ['1-day Nueva Era eco park and waterfall under 900', { cat: 'natural_attraction', lgu: 'nueva-era', budget: 'budget', days: 1, scenery: 'highland' }],
  ['1-day Carasi highland river trek under 1000', { cat: 'recreation_adventure', lgu: 'carasi', budget: 'budget', days: 1, scenery: 'highland' }],
  ['2-day Laoag city cafe dining and museums for 4000', { cat: 'food_culinary', lgu: 'laoag-city', budget: 'moderate', days: 2 }],
  ['5-day grand Ilocos Norte coastal and heritage trip with 8000', { cat: 'heritage_cultural', budget: 'flexible', days: 5, scenery: 'coastal' }],
];

async function runEvaluation() {
  console.log('\n==================================================================');
  console.log('  NORTE BOUND — CASE STUDY REVISION 3 EVALUATION SUITE');
  console.log('==================================================================');

  // 1. Live Gemini Check + Eval-Obj B.2: 50 Held-Out NLP Prompts (>= 85% exact match)
  const liveGemini = await parseNaturalLanguageIntent({
    prompt: '2-day heritage church and beach tour in Paoay and Pagudpud under 2000 php',
  });
  console.log(`[Live AI] source=${liveGemini.source} | categories=${liveGemini.extractedPreferences.categories.join(',')} | lgus=${liveGemini.extractedPreferences.preferredLgus.join(',')}`);

  let nlpPassed = 0;
  const failures = [];
  for (const [prompt, expected] of NLP_TEST_SET) {
    const { extractedPreferences: got } = await parseNaturalLanguageIntent({
      prompt,
      skipRemoteAi: true,
    });
    const checks = [];
    if (expected.cat) checks.push(got.categories.includes(expected.cat));
    if (expected.lgu) checks.push(got.preferredLgus.includes(expected.lgu));
    if (expected.cluster) checks.push(got.preferredClusters.includes(expected.cluster));
    if (expected.budget) checks.push(got.budgetLevel === expected.budget);
    if (expected.days) checks.push(got.availableDays === expected.days);
    if (expected.hours) checks.push(got.availableHoursPerDay === expected.hours);
    if (expected.scenery) checks.push(got.preferredScenery.includes(expected.scenery));

    if (checks.every(Boolean)) {
      nlpPassed += 1;
    } else {
      failures.push({ prompt, expected, got });
    }
  }
  const nlpAccuracy = (nlpPassed / NLP_TEST_SET.length) * 100;
  console.log(`[Eval B.2] NLP Extraction Accuracy: ${nlpPassed}/${NLP_TEST_SET.length} (${nlpAccuracy.toFixed(1)}%) — Target >= 85%`);
  if (failures.length > 0 && nlpAccuracy < 85) {
    console.log('Sample NLP mismatches:', JSON.stringify(failures.slice(0, 3), null, 2));
  }
  assert(nlpAccuracy >= 85, `Expected >= 85% NLP accuracy, got ${nlpAccuracy.toFixed(1)}%`);

  // 2. Eval-Obj B.3 & B.6: Recommendations >= 30% Lesser-Known Quota & Feasibility
  const recResult = await getRecommendations({
    categories: ['natural_attraction', 'heritage_cultural'],
    interestTags: [],
    preferredScenery: ['coastal', 'highland'],
    preferredLgus: [],
    preferredClusters: [],
    budgetAmount: 2500,
    budgetLevel: 'moderate',
    budgetScope: 'perPerson',
    availableDays: 2,
    availableHoursPerDay: 9,
    startTime: '08:00',
    endTime: '18:00',
    originLguCode: 'laoag-city',
    groupSize: 1,
    transportMode: 'motorcycle',
    pacing: 'moderate',
    limit: 10,
  });
  console.log(`[Eval B.6] Recommendations Dispersal Ratio: ${(recResult.dispersalSummary.lesserKnownRatio * 100).toFixed(0)}% (${recResult.dispersalSummary.lesserKnownCount}/${recResult.dispersalSummary.totalCount}) — Target >= 30%`);
  assert(recResult.dispersalSummary.lesserKnownRatio >= 0.3, 'Recommendations must include >= 30% lesser-known/community stops');

  const feasiblePlan = await generateFeasibleItinerary({
    categories: ['natural_attraction', 'heritage_cultural', 'agro_eco_tourism'],
    interestTags: [],
    preferredScenery: [],
    preferredLgus: [],
    preferredClusters: [],
    budgetAmount: 3000,
    budgetLevel: 'moderate',
    budgetScope: 'perPerson',
    availableDays: 2,
    availableHoursPerDay: 9,
    startTime: '08:00',
    endTime: '18:00',
    originLguCode: 'laoag-city',
    groupSize: 1,
    transportMode: 'motorcycle',
    pacing: 'moderate',
  });
  console.log(`[Eval B.3] Feasible Plan: ${feasiblePlan.feasibilityReport.isFeasible} | Stops: ${feasiblePlan.totalStops} | Lesser-Known: ${(feasiblePlan.lesserKnownRatio * 100).toFixed(0)}% | Cost: ₱${feasiblePlan.expenseBreakdown.totalEstimatedCost}`);
  assert.equal(feasiblePlan.feasibilityReport.isFeasible, true);
  assert(feasiblePlan.lesserKnownRatio >= 0.3, `Itinerary lesser-known ratio ${feasiblePlan.lesserKnownRatio} < 0.30`);

  // Verify infeasible detection when time/budget constraints cannot be satisfied
  const infeasiblePlan = await generateFeasibleItinerary({
    categories: [],
    interestTags: [],
    preferredScenery: [],
    preferredLgus: ['adams'],
    preferredClusters: [],
    budgetAmount: 5,
    budgetLevel: 'budget',
    budgetScope: 'perPerson',
    availableDays: 1,
    availableHoursPerDay: 2,
    startTime: '22:00',
    endTime: '23:00',
    originLguCode: 'laoag-city',
    groupSize: 1,
    transportMode: 'publicCommute',
    pacing: 'relaxed',
  });
  console.log(`[Eval B.3] Infeasible Violation Detection: isFeasible=${infeasiblePlan.feasibilityReport.isFeasible} | violations=${infeasiblePlan.feasibilityReport.violatedConstraints.length}`);
  assert.equal(infeasiblePlan.feasibilityReport.isFeasible, false);
  assert(infeasiblePlan.feasibilityReport.violatedConstraints.length > 0);

  // 3. Eval-Obj B.5: Dynamic Recalculation Latency (< 10,000 ms for <= 10 stops)
  const recalcStart = performance.now();
  const adjustedPlan = await generateFeasibleItinerary({
    categories: ['natural_attraction', 'heritage_cultural'],
    interestTags: [],
    preferredScenery: [],
    preferredLgus: [],
    preferredClusters: ['northern_coast'],
    budgetAmount: 2000,
    budgetLevel: 'moderate',
    budgetScope: 'perPerson',
    availableDays: 2,
    availableHoursPerDay: 6,
    startTime: '09:00',
    endTime: '15:00',
    originLguCode: 'pagudpud',
    groupSize: 2,
    transportMode: 'privateCar',
    pacing: 'moderate',
    excludedDestinationIds: [1],
  });
  const recalcElapsedMs = Math.round(performance.now() - recalcStart);
  console.log(`[Eval B.5] Dynamic Recalculation Latency: ${recalcElapsedMs} ms (server engine: ${adjustedPlan.recalculationTimeMs} ms) — Target < 10000 ms`);
  assert(recalcElapsedMs < 10000, 'Dynamic recalculation exceeded 10 seconds');

  // 4. Eval-Obj B.9: Change-Detection Matrix (Automatic Detection)
  const changeReport = detectSavedItineraryChanges({
    itinerary: {
      id: 99,
      title: 'Test Plan',
      total_days: 1,
      total_estimated_cost: 500,
      preferences_snapshot: {},
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    },
    items: [
      {
        item_id: 1,
        destination_id: 10,
        slug: 'stop-a',
        name: 'Closed Spot',
        lgu_code: 'paoay',
        lgu_name: 'Paoay',
        category_code: 'heritage_cultural',
        latitude: 18.1,
        longitude: 120.5,
        day_number: 1,
        sequence_order: 1,
        scheduled_time: '09:00-10:00',
        meal_window: null,
        estimated_duration_minutes: 60,
        travel_time_from_prev_minutes: 10,
        verification_status: 'verified',
        temporarily_closed: true,
        opening_time: '08:00:00',
        closing_time: '17:00:00',
        is_24_hours: false,
        entrance_fee_adult: 30,
        mandatory_activity_fee: 0,
      },
      {
        item_id: 2,
        destination_id: 11,
        slug: 'stop-b',
        name: 'Shifted Hours Spot',
        lgu_code: 'laoag-city',
        lgu_name: 'Laoag City',
        category_code: 'heritage_cultural',
        latitude: 18.2,
        longitude: 120.6,
        day_number: 1,
        sequence_order: 2,
        scheduled_time: '17:00-18:00',
        meal_window: null,
        estimated_duration_minutes: 60,
        travel_time_from_prev_minutes: 20,
        verification_status: 'verified',
        temporarily_closed: false,
        opening_time: '08:00:00',
        closing_time: '16:30:00',
        is_24_hours: false,
        entrance_fee_adult: 0,
        mandatory_activity_fee: 0,
      },
      {
        item_id: 3,
        destination_id: 12,
        slug: 'stop-c',
        name: 'Unverified Spot',
        lgu_code: 'adams',
        lgu_name: 'Adams',
        category_code: 'natural_attraction',
        latitude: 18.4,
        longitude: 120.9,
        day_number: 1,
        sequence_order: 3,
        scheduled_time: '10:00-11:00',
        meal_window: null,
        estimated_duration_minutes: 60,
        travel_time_from_prev_minutes: 20,
        verification_status: 'needs_field_verification',
        temporarily_closed: false,
        opening_time: '08:00:00',
        closing_time: '17:00:00',
        is_24_hours: false,
        entrance_fee_adult: 0,
        mandatory_activity_fee: 0,
      },
    ],
  });
  const detectedTypes = changeReport.detectedChanges.map((c) => c.type);
  console.log(`[Eval B.9] Change-Detection Matrix: ${detectedTypes.join(', ')}`);
  assert(detectedTypes.includes('destination_closed'));
  assert(detectedTypes.includes('schedule_shift'));
  assert(detectedTypes.includes('verification_revoked'));

  console.log('\n🎉 All Case Study Revision 3 Backend Evaluation Benchmarks PASSED!\n');
}

try {
  await runEvaluation();
} finally {
  await closePool();
}
