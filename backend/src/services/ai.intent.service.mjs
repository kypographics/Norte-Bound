import { env } from '../config/env.mjs';
import { query } from '../config/db.mjs';
import { parseJsonArray } from '../utils/destination.mapper.mjs';

const SCENERY_KEYWORDS = {
  coastal: ['beach', 'coast', 'coastal', 'sea', 'ocean', 'sand', 'cove', 'surf', 'lagoon', 'lighthouse', 'sunset', 'windmill', 'shore', 'cliff'],
  highland: ['mountain', 'highland', 'falls', 'waterfall', 'trek', 'hike', 'pine', 'ridge', 'river', 'forest', 'cold', 'cool', 'peak', 'upland'],
  heritage_urban: ['church', 'heritage', 'museum', 'historic', 'history', 'spanish', 'baroque', 'town', 'city', 'ancestral', 'landmark', 'plaza', 'bell tower'],
  rural_agro: ['farm', 'agri', 'agro', 'vineyard', 'rice', 'craft', 'weaving', 'pottery', 'salt', 'village', 'community', 'honey', 'dragonfruit'],
};

const CATEGORY_KEYWORDS = {
  natural_attraction: ['beach', 'falls', 'waterfall', 'nature', 'dune', 'rock', 'cave', 'mountain', 'sea', 'sunset', 'scenic', 'view', 'park', 'lake', 'cove', 'island'],
  heritage_cultural: ['church', 'heritage', 'museum', 'historic', 'history', 'shrine', 'bell tower', 'baroque', 'colonial', 'culture', 'ancestral', 'landmark'],
  food_culinary: ['food', 'eat', 'restaurant', 'cafe', 'coffee', 'empanada', 'bagnet', 'longganisa', 'dining', 'lunch', 'dinner', 'culinary', 'local dish', 'miki', 'biscocho', 'eatery'],
  agro_eco_tourism: ['farm', 'vineyard', 'dragonfruit', 'windmill', 'wind farm', 'eco', 'agri', 'rice', 'solar', 'honey', 'forest', 'wine', 'bugnay'],
  artisan_craft_experience: ['craft', 'weaving', 'abel', 'pottery', 'burnay', 'damili', 'salt', 'asin', 'bamboo', 'workshop', 'artisan', 'loom'],
  recreation_adventure: ['4x4', 'sandboard', 'surf', 'kayak', 'trek', 'zipline', 'atv', 'adventure', 'hike', 'camping', 'swim', 'waterpark', 'trail'],
};

const CLUSTER_KEYWORDS = {
  northern_coast: ['northern coast', 'north coast', 'north circuit'],
  central_urban_heritage: ['central circuit', 'central urban', 'central heritage'],
  southern_heritage_coast: ['southern coast', 'south coast', 'southern heritage'],
  eastern_agri_highland: ['eastern highland', 'eastern circuit', 'agri highland', 'eastern agri'],
};

function deterministicExtract(prompt, lgus, tags) {
  const lower = prompt.toLowerCase();

  // 1. Categories
  const categories = new Set();
  for (const [code, words] of Object.entries(CATEGORY_KEYWORDS)) {
    if (words.some((w) => lower.includes(w))) {
      categories.add(code);
    }
  }

  // 2. Interest tags from DB synonyms
  const interestTags = new Set();
  for (const tag of tags) {
    const synonyms = parseJsonArray(tag.ai_synonyms);
    const terms = [tag.display_name, tag.tag_slug.replace(/-/g, ' '), ...synonyms]
      .filter(Boolean)
      .map((t) => String(t).toLowerCase());
    if (terms.some((term) => term.length >= 3 && lower.includes(term))) {
      interestTags.add(tag.tag_slug);
      categories.add(tag.category_code);
    }
  }

  // 3. Preferred Scenery
  const preferredScenery = [];
  for (const [scenery, words] of Object.entries(SCENERY_KEYWORDS)) {
    if (words.some((w) => lower.includes(w))) {
      preferredScenery.push(scenery);
    }
  }

  // 4. Preferred LGUs & Clusters (word-boundary safe; avoid matching 'marcos' inside unrelated words)
  const preferredLgus = [];
  for (const lgu of lgus) {
    const baseName = lgu.name.toLowerCase().replace(/\s*\(.*?\)/g, '').replace(/\s+city$/, '').trim();
    const slugName = lgu.lgu_code.replace(/-/g, ' ');
    const esc = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const re = new RegExp(`\\b(?:${esc(baseName)}|${esc(slugName)})\\b`, 'i');
    if (re.test(lower)) {
      preferredLgus.push(lgu.lgu_code);
    }
  }
  const preferredClusters = [];
  for (const [cluster, words] of Object.entries(CLUSTER_KEYWORDS)) {
    if (words.some((w) => lower.includes(w))) {
      preferredClusters.push(cluster);
    }
  }

  // 5. Budget
  let budgetAmount = null;
  let budgetLevel = 'moderate';
  let budgetScope = 'perPerson';

  const phpMatch = lower.match(/(?:₱|php|p\s*|under\s+|budget\s*(?:of\s*)?)(\d{3,6}(?:,\d{3})?)/i);
  if (phpMatch) {
    budgetAmount = Number(phpMatch[1].replace(/,/g, ''));
  }
  if (/cheap|budget|low[-\s]?cost|free|affordable|tipid|backpack/i.test(lower) || (budgetAmount !== null && budgetAmount <= 1000)) {
    budgetLevel = 'budget';
    budgetAmount ??= 1000;
  } else if (/luxury|flexible|splurge|unlimited|no budget limit/i.test(lower) || (budgetAmount !== null && budgetAmount >= 5000)) {
    budgetLevel = 'flexible';
    budgetAmount ??= 6000;
  } else {
    budgetAmount ??= 2500;
  }

  if (/total\s+group|for\s+all|group\s+budget|altogether/i.test(lower)) {
    budgetScope = 'totalGroup';
  }

  // 6. Available Time (days, hours, window)
  let availableDays = 1;
  const daysMatch = lower.match(/(\d+)\s*[-\s]?days?/i);
  if (daysMatch) {
    availableDays = Math.min(7, Math.max(1, Number(daysMatch[1])));
  } else if (/weekend/i.test(lower)) {
    availableDays = 2;
  } else if (/half[-\s]?day/i.test(lower)) {
    availableDays = 1;
  }

  let availableHoursPerDay = 9;
  let startTime = '08:00';
  let endTime = '18:00';
  const hoursMatch = lower.match(/(\d+)\s*[-\s]?hours?/i);
  if (hoursMatch) {
    availableHoursPerDay = Math.min(14, Math.max(2, Number(hoursMatch[1])));
  } else if (/half[-\s]?day/i.test(lower)) {
    availableHoursPerDay = 4;
    endTime = '12:30';
  } else if (/morning/i.test(lower) && !/afternoon|evening|full\s*day/i.test(lower)) {
    availableHoursPerDay = 5;
    startTime = '07:30';
    endTime = '12:30';
  } else if (/afternoon/i.test(lower) && !/morning|full\s*day/i.test(lower)) {
    availableHoursPerDay = 5;
    startTime = '13:00';
    endTime = '18:00';
  }

  // Group size, transport, pacing
  let groupSize = 1;
  const groupMatch = lower.match(/(\d+)\s*(?:people|persons|pax|travelers|friends)/i);
  if (groupMatch) {
    groupSize = Math.min(50, Math.max(1, Number(groupMatch[1])));
  } else if (/couple|two of us|partner/i.test(lower)) {
    groupSize = 2;
  } else if (/family|barkada/i.test(lower)) {
    groupSize = 4;
  }

  let transportMode = 'motorcycle';
  if (/commute|bus|jeep|tricycle|public\s+transport/i.test(lower)) {
    transportMode = 'publicCommute';
  } else if (/car|van|suv|drive|sedan/i.test(lower)) {
    transportMode = 'privateCar';
  }

  let pacing = 'moderate';
  if (/relax|slow|chill|easy/i.test(lower)) pacing = 'relaxed';
  else if (/pack|fast|maxim|everything/i.test(lower)) pacing = 'packed';

  return {
    categories: [...categories],
    interestTags: [...interestTags],
    preferredScenery,
    preferredLgus,
    preferredClusters,
    budgetAmount,
    budgetLevel,
    budgetScope,
    availableDays,
    availableHoursPerDay,
    startTime,
    endTime,
    groupSize,
    transportMode,
    pacing,
  };
}

async function tryGeminiExtraction(prompt, lgus, categories, tags, skipRemoteAi = false) {
  const apiKey = env.GEMINI_API_KEY;
  if (skipRemoteAi || !apiKey || apiKey.includes('placeholder') || apiKey.includes('your_gemini')) {
    return null;
  }

  const lguList = lgus.map((l) => `${l.lgu_code} (${l.name}, ${l.tourism_cluster})`).join(', ');
  const catList = categories.map((c) => c.category_code).join(', ');
  const tagList = tags.map((t) => t.tag_slug).join(', ');

  const systemPrompt = [
    'Extract travel preferences for Ilocos Norte from the user request into JSON.',
    `Allowed categories: ${catList}.`,
    `Allowed interestTags: ${tagList}.`,
    `Allowed preferredLgus: ${lguList}.`,
    'Allowed preferredClusters: northern_coast, central_urban_heritage, southern_heritage_coast, eastern_agri_highland.',
    'Allowed preferredScenery: coastal, highland, heritage_urban, rural_agro.',
    'Only use allowed codes. Never invent destination names or facts.',
  ].join(' ');

  const responseSchema = {
    type: 'OBJECT',
    properties: {
      categories: { type: 'ARRAY', items: { type: 'STRING' } },
      interestTags: { type: 'ARRAY', items: { type: 'STRING' } },
      preferredScenery: { type: 'ARRAY', items: { type: 'STRING' } },
      preferredLgus: { type: 'ARRAY', items: { type: 'STRING' } },
      preferredClusters: { type: 'ARRAY', items: { type: 'STRING' } },
      budgetAmount: { type: 'NUMBER', nullable: true },
      budgetLevel: { type: 'STRING' },
      budgetScope: { type: 'STRING' },
      availableDays: { type: 'INTEGER' },
      availableHoursPerDay: { type: 'NUMBER' },
      startTime: { type: 'STRING' },
      endTime: { type: 'STRING' },
      groupSize: { type: 'INTEGER' },
      transportMode: { type: 'STRING' },
      pacing: { type: 'STRING' },
    },
  };

  for (const model of ['gemini-3.1-flash-lite-preview', 'gemini-3-flash-preview', 'gemini-flash-latest']) {
    try {
      const res = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${encodeURIComponent(apiKey)}`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            contents: [{ role: 'user', parts: [{ text: `${systemPrompt}\n\nRequest: ${prompt}` }] }],
            generationConfig: {
              responseMimeType: 'application/json',
              responseSchema,
              temperature: 0.1,
            },
          }),
          signal: AbortSignal.timeout(8000),
        },
      );
      if (!res.ok) continue;
      const payload = await res.json();
      const text = payload.candidates?.[0]?.content?.parts?.[0]?.text;
      if (!text) continue;
      return { model, data: JSON.parse(text) };
    } catch {
      /* try next model */
    }
  }
  return null;
}

export async function parseNaturalLanguageIntent({ prompt, originLguCode, skipRemoteAi = false }) {
  const [lgus, categories, tags] = await Promise.all([
    query('SELECT lgu_code, name, tourism_cluster FROM lgus'),
    query('SELECT category_code, name FROM categories'),
    query('SELECT tag_slug, display_name, category_code, ai_synonyms FROM interest_tags'),
  ]);

  const fallback = deterministicExtract(prompt, lgus, tags);
  const aiResponse = await tryGeminiExtraction(prompt, lgus, categories, tags, skipRemoteAi);
  const aiResult = aiResponse?.data ?? null;

  const validCats = new Set(categories.map((c) => c.category_code));
  const validTags = new Set(tags.map((t) => t.tag_slug));
  const validLgus = new Set(lgus.map((l) => l.lgu_code));
  const validClusters = new Set(Object.keys(CLUSTER_KEYWORDS));
  const validScenery = new Set(Object.keys(SCENERY_KEYWORDS));

  const mergeList = (aiList, fbList, validSet) => {
    const combined = [...(Array.isArray(aiList) ? aiList : []), ...fbList];
    return [...new Set(combined.filter((item) => validSet.has(item)))];
  };

  const extracted = aiResult
    ? {
        categories: mergeList(aiResult.categories, fallback.categories, validCats),
        interestTags: mergeList(aiResult.interestTags, fallback.interestTags, validTags),
        preferredScenery: mergeList(aiResult.preferredScenery, fallback.preferredScenery, validScenery),
        preferredLgus: mergeList(aiResult.preferredLgus, fallback.preferredLgus, validLgus),
        preferredClusters: mergeList(aiResult.preferredClusters, fallback.preferredClusters, validClusters),
        budgetAmount:
          typeof aiResult.budgetAmount === 'number' && aiResult.budgetAmount > 0
            ? aiResult.budgetAmount
            : fallback.budgetAmount,
        budgetLevel: ['budget', 'moderate', 'flexible'].includes(aiResult.budgetLevel)
          ? aiResult.budgetLevel
          : fallback.budgetLevel,
        budgetScope: ['perPerson', 'totalGroup'].includes(aiResult.budgetScope)
          ? aiResult.budgetScope
          : fallback.budgetScope,
        availableDays:
          Number.isInteger(aiResult.availableDays) && aiResult.availableDays >= 1
            ? Math.min(7, aiResult.availableDays)
            : fallback.availableDays,
        availableHoursPerDay:
          typeof aiResult.availableHoursPerDay === 'number' && aiResult.availableHoursPerDay >= 2
            ? Math.min(14, aiResult.availableHoursPerDay)
            : fallback.availableHoursPerDay,
        startTime: /^\d{2}:\d{2}$/.test(aiResult.startTime ?? '') ? aiResult.startTime : fallback.startTime,
        endTime: /^\d{2}:\d{2}$/.test(aiResult.endTime ?? '') ? aiResult.endTime : fallback.endTime,
        groupSize:
          Number.isInteger(aiResult.groupSize) && aiResult.groupSize >= 1
            ? Math.min(50, aiResult.groupSize)
            : fallback.groupSize,
        transportMode: ['motorcycle', 'privateCar', 'publicCommute'].includes(aiResult.transportMode)
          ? aiResult.transportMode
          : fallback.transportMode,
        pacing: ['relaxed', 'moderate', 'packed'].includes(aiResult.pacing)
          ? aiResult.pacing
          : fallback.pacing,
      }
    : fallback;

  return {
    source: aiResponse ? aiResponse.model : 'deterministic-rule-parser',
    originLguCode: originLguCode && validLgus.has(originLguCode) ? originLguCode : 'laoag-city',
    extractedPreferences: extracted,
    requiresUserConfirmation: true,
  };
}
