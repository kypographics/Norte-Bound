// NORTE BOUND — Curator Admin Portal
// Plain vanilla ES module-free browser script aligned strictly to /api/v1 contracts.

const DEFAULT_API_BASE = 'http://localhost:5000/api/v1';
const HERO_IMAGE_URL =
  'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/30/Cape_Bojeador_Lighthouse_Landscaped_Gardens.jpg/960px-Cape_Bojeador_Lighthouse_Landscaped_Gardens.jpg';

const DAY_NAMES = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

const ENTITY_TYPE_LABELS = {
  attraction: 'Attraction',
  food_establishment: 'Food Establishment',
  cultural_experience: 'Cultural Experience',
  activity_hub: 'Activity Hub',
};

const POPULARITY_TIER_LABELS = {
  iconic_hub: 'Iconic Hub',
  moderate: 'Moderate',
  hidden_gem: 'Hidden Gem',
};

const ROAD_CONDITION_LABELS = {
  paved_all_weather: 'Paved (All-Weather)',
  rough_patch: 'Rough Patch',
  '4x4_or_trek_required': '4x4 or Trek Required',
};

const SOURCE_TYPE_LABELS = {
  provincial_tourism: 'Provincial Tourism Office',
  lgu_official: 'LGU Official Registry',
  dot_accredited: 'DOT Accredited',
  verified_establishment: 'Verified Establishment',
};

function resolveApiBase() {
  const params = new URLSearchParams(window.location.search);
  const override = params.get('api');
  if (override) {
    const cleaned = override.trim().replace(/\/+$/, '');
    localStorage.setItem('nb_api_base', cleaned);
    return cleaned;
  }
  return (localStorage.getItem('nb_api_base') || DEFAULT_API_BASE).replace(/\/+$/, '');
}

const API_BASE = resolveApiBase();

function readStoredUser() {
  try {
    return JSON.parse(localStorage.getItem('nb_admin_user') || 'null');
  } catch {
    return null;
  }
}

const state = {
  token: localStorage.getItem('nb_admin_token') || null,
  user: readStoredUser(),
  apiHealthy: null,
  renderedShell: null,
  loading: false,
  loginLoading: false,
  loginError: null,
  destinations: [],
  clusters: [],
  lgus: [],
  lguTotal: 23,
  categories: [],
  interestTags: [],
  filter: {
    search: '',
    cluster: '',
    lgu: '',
    category: '',
    status: '',
  },
  viewMode: localStorage.getItem('nb_admin_view') === 'grid' ? 'grid' : 'table',
  pendingStatusIds: new Set(),
  modal: null,
  deleteModal: null,
};

function escapeHtml(value) {
  return String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function slugify(value) {
  return String(value ?? '')
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .replace(/-{2,}/g, '-')
    .slice(0, 191);
}

function formatPhp(amount) {
  const num = Number(amount || 0);
  if (!Number.isFinite(num) || num <= 0) {
    return 'Free';
  }
  return new Intl.NumberFormat('en-PH', {
    style: 'currency',
    currency: 'PHP',
    maximumFractionDigits: num % 1 === 0 ? 0 : 2,
  }).format(num);
}

function getInitials(name) {
  const parts = String(name ?? '')
    .trim()
    .split(/\s+/)
    .filter(Boolean);
  if (parts.length === 0) return 'NB';
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
  return `${parts[0][0]}${parts[1][0]}`.toUpperCase();
}

function humanizeCluster(cluster) {
  if (!cluster) return 'Unspecified';
  const match = state.clusters.find((c) => c.cluster === cluster);
  if (match?.label) return match.label;
  return String(cluster)
    .split('_')
    .filter(Boolean)
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
    .join(' ');
}

function showToast(message, type = 'info') {
  const root = document.getElementById('toast-root');
  if (!root) return;

  const toast = document.createElement('div');
  toast.className = `toast${type === 'error' ? ' toast--error' : ''}`;
  toast.setAttribute('role', 'status');

  const span = document.createElement('span');
  span.textContent = message;

  const closeBtn = document.createElement('button');
  closeBtn.type = 'button';
  closeBtn.className = 'toast__close';
  closeBtn.setAttribute('aria-label', 'Dismiss notification');
  closeBtn.textContent = '✕';
  closeBtn.addEventListener('click', () => toast.remove());

  toast.append(span, closeBtn);
  root.appendChild(toast);

  window.setTimeout(() => {
    if (toast.isConnected) toast.remove();
  }, 4200);
}

function extractApiError(data, status) {
  const errObj = data?.error;
  if (errObj && typeof errObj === 'object') {
    if (Array.isArray(errObj.details) && errObj.details.length > 0) {
      return errObj.details
        .map((d) => (d.field ? `${d.field}: ${d.message}` : d.message))
        .join(' · ');
    }
    if (errObj.message) return errObj.message;
  }
  if (typeof errObj === 'string') return errObj;
  if (data?.message) return data.message;
  return `Request failed with status ${status}`;
}

async function apiRequest(endpoint, options = {}) {
  const headers = {
    'Content-Type': 'application/json',
    ...(state.token ? { Authorization: `Bearer ${state.token}` } : {}),
    ...(options.headers || {}),
  };

  let res;
  try {
    res = await fetch(`${API_BASE}${endpoint}`, {
      ...options,
      headers,
    });
  } catch {
    throw new Error(`Unable to reach API at ${API_BASE}. Check that the backend server is running.`);
  }

  let data = null;
  try {
    data = await res.json();
  } catch {
    data = null;
  }

  if (!res.ok) {
    if (res.status === 401 && endpoint !== '/auth/login' && state.token) {
      clearSession();
      showToast('Your curator session expired. Please sign in again.', 'error');
      renderApp();
    }
    throw new Error(extractApiError(data, res.status));
  }

  return data;
}

function saveSession(token, user) {
  state.token = token;
  state.user = user;
  localStorage.setItem('nb_admin_token', token);
  localStorage.setItem('nb_admin_user', JSON.stringify(user));
}

function clearSession() {
  state.token = null;
  state.user = null;
  state.destinations = [];
  state.modal = null;
  state.deleteModal = null;
  localStorage.removeItem('nb_admin_token');
  localStorage.removeItem('nb_admin_user');
}

async function checkApiHealth() {
  try {
    const res = await apiRequest('/health');
    state.apiHealthy = res?.status === 'ok';
  } catch {
    state.apiHealthy = false;
  }
  updateHealthBadge();
}

function updateHealthBadge() {
  const el = document.getElementById('api-health-pill');
  if (!el) return;
  if (state.apiHealthy === true) {
    el.innerHTML = '<span class="status-dot" aria-hidden="true"></span><span>API Live</span>';
  } else if (state.apiHealthy === false) {
    el.innerHTML = '<span class="status-dot" style="background:#fca5a5" aria-hidden="true"></span><span>API Offline</span>';
  } else {
    el.innerHTML = '<span class="status-dot" style="background:#fcd34d" aria-hidden="true"></span><span>Checking API…</span>';
  }
}

async function loadMetadata() {
  const [lgusRes, taxRes] = await Promise.all([
    apiRequest('/destinations/lgus'),
    apiRequest('/destinations/taxonomy'),
  ]);

  const clusters = Array.isArray(lgusRes?.data) ? lgusRes.data : [];
  state.clusters = clusters;
  state.lguTotal = Number(lgusRes?.total) || clusters.reduce((sum, c) => sum + (c.lgus?.length || 0), 0) || 22;

  const flatLgus = [];
  for (const group of clusters) {
    for (const lgu of group.lgus || []) {
      flatLgus.push({
        ...lgu,
        cluster: group.cluster,
        clusterLabel: group.label || humanizeCluster(group.cluster),
      });
    }
  }
  flatLgus.sort((a, b) => a.name.localeCompare(b.name));
  state.lgus = flatLgus;

  state.categories = Array.isArray(taxRes?.data?.categories) ? taxRes.data.categories : [];
  state.interestTags = Array.isArray(taxRes?.data?.interestTags) ? taxRes.data.interestTags : [];

  populateFilterDropdowns();
}

async function loadDestinations() {
  state.loading = true;
  renderKpiAndCatalog();

  try {
    const first = await apiRequest('/destinations?limit=100&page=1');
    const all = Array.isArray(first?.data) ? [...first.data] : [];
    const totalPages = Number(first?.pagination?.totalPages) || 1;

    if (totalPages > 1) {
      const pageRequests = [];
      for (let page = 2; page <= totalPages; page += 1) {
        pageRequests.push(apiRequest(`/destinations?limit=100&page=${page}`));
      }
      const rest = await Promise.all(pageRequests);
      for (const chunk of rest) {
        if (Array.isArray(chunk?.data)) {
          all.push(...chunk.data);
        }
      }
    }

    state.destinations = all;
    state.apiHealthy = true;
    updateHealthBadge();
  } catch (err) {
    showToast(err.message || 'Failed to load destinations.', 'error');
  } finally {
    state.loading = false;
    renderKpiAndCatalog();
  }
}

async function bootstrapDashboard() {
  state.loading = true;
  renderKpiAndCatalog();
  try {
    await Promise.all([loadMetadata(), loadDestinations()]);
  } catch (err) {
    if (state.token) {
      showToast(err.message || 'Could not load registry data.', 'error');
    }
  } finally {
    state.loading = false;
    renderKpiAndCatalog();
  }
}

function getFilteredDestinations() {
  const q = state.filter.search.trim().toLowerCase();
  const { cluster, lgu, category, status } = state.filter;

  return state.destinations.filter((d) => {
    if (cluster && d.lgu?.cluster !== cluster) return false;
    if (lgu && d.lgu?.code !== lgu) return false;
    if (category && d.category?.code !== category) return false;
    if (status && d.verification?.status !== status) return false;

    if (!q) return true;
    const tagMatch = Array.isArray(d.tags)
      && d.tags.some((t) => `${t.name || ''} ${t.slug || ''}`.toLowerCase().includes(q));
    return (
      String(d.name || '').toLowerCase().includes(q)
      || String(d.slug || '').toLowerCase().includes(q)
      || String(d.lgu?.name || '').toLowerCase().includes(q)
      || String(d.address || '').toLowerCase().includes(q)
      || tagMatch
    );
  });
}

function renderApp() {
  const isAdmin = Boolean(state.token && state.user && state.user.role === 'admin');

  if (!isAdmin) {
    if (state.renderedShell !== 'login') {
      state.renderedShell = 'login';
      mountLoginView();
    } else {
      updateLoginError();
    }
    return;
  }

  if (state.renderedShell !== 'dashboard') {
    state.renderedShell = 'dashboard';
    mountDashboardShell();
    populateFilterDropdowns();
    renderKpiAndCatalog();
  } else {
    renderKpiAndCatalog();
  }
}

function mountLoginView() {
  const app = document.getElementById('app');
  app.innerHTML = `
    <div class="auth-shell">
      <aside class="auth-visual">
        <img
          src="${escapeHtml(HERO_IMAGE_URL)}"
          alt="Cape Bojeador Lighthouse overlooking Burgos coastline in Ilocos Norte"
          class="auth-visual__img"
        />
        <div class="auth-visual__scrim" aria-hidden="true"></div>
        <div class="auth-visual__top">
          <div class="auth-badge">NORTE BOUND · Curator Registry</div>
          <div class="auth-badge">Province-Wide Registry</div>
        </div>
        <div class="auth-visual__bottom">
          <p class="auth-visual__eyebrow">Zero-Hallucination Tourism Governance</p>
          <h2 class="auth-visual__headline">Field-verified Ilocos Norte destinations in one source of truth.</h2>
          <p class="auth-visual__copy">
            Curators audit entrance fees, operating hours, road conditions, and LGU dispersal balance before places enter traveler itineraries.
          </p>
          <p class="auth-visual__credit">Cape Bojeador Lighthouse · Burgos, Ilocos Norte</p>
        </div>
      </aside>

      <main class="auth-pane">
        <div class="auth-card">
          <div class="auth-card__brand">
            <div class="brand-mark" aria-hidden="true">NB</div>
            <div>
              <div style="font-weight:700;font-size:15px;letter-spacing:-0.02em;">NORTE BOUND</div>
              <div style="font-size:12px;color:var(--forest-muted);">Curator Admin Portal</div>
            </div>
          </div>

          <h1 class="auth-card__title">Sign in to Curate</h1>
          <p class="auth-card__subtitle">Administrator role required to verify or edit province records.</p>

          <div id="login-error-slot"></div>

          <form id="login-form" class="auth-form" novalidate>
            <div class="field">
              <label for="login-email" class="field-label">Curator Email</label>
              <input
                type="email"
                id="login-email"
                name="email"
                class="input"
                autocomplete="email"
                placeholder="curator@nortebound.ph"
                required
              />
            </div>

            <div class="field">
              <label for="login-password" class="field-label">Password</label>
              <div class="password-wrap">
                <input
                  type="password"
                  id="login-password"
                  name="password"
                  class="input"
                  autocomplete="current-password"
                  placeholder="Enter password"
                  required
                />
                <button
                  type="button"
                  id="toggle-password-btn"
                  class="password-toggle"
                  aria-label="Show password"
                >Show</button>
              </div>
            </div>

            <button type="submit" id="login-submit-btn" class="btn btn-primary btn-block">
              Sign In as Curator
            </button>
          </form>

          <div class="auth-footer-note">
            <span>API: <code class="num">${escapeHtml(API_BASE)}</code></span>
            <span id="login-health-label"></span>
          </div>
        </div>
      </main>
    </div>
  `;

  updateLoginError();

  const toggleBtn = document.getElementById('toggle-password-btn');
  const pwInput = document.getElementById('login-password');
  toggleBtn?.addEventListener('click', () => {
    const isHidden = pwInput.type === 'password';
    pwInput.type = isHidden ? 'text' : 'password';
    toggleBtn.textContent = isHidden ? 'Hide' : 'Show';
    toggleBtn.setAttribute('aria-label', isHidden ? 'Hide password' : 'Show password');
  });

  const form = document.getElementById('login-form');
  form?.addEventListener('submit', handleLogin);
}

function updateLoginError() {
  const slot = document.getElementById('login-error-slot');
  if (!slot) return;
  if (!state.loginError) {
    slot.innerHTML = '';
    return;
  }
  slot.innerHTML = `
    <div class="alert alert-danger" role="alert" style="margin-bottom:16px;">
      <span>${escapeHtml(state.loginError)}</span>
    </div>
  `;
}

async function handleLogin(event) {
  event.preventDefault();
  if (state.loginLoading) return;

  const email = document.getElementById('login-email')?.value.trim() || '';
  const password = document.getElementById('login-password')?.value || '';

  if (!email || !password) {
    state.loginError = 'Enter both your curator email and password.';
    updateLoginError();
    return;
  }

  state.loginLoading = true;
  state.loginError = null;
  updateLoginError();

  const submitBtn = document.getElementById('login-submit-btn');
  if (submitBtn) {
    submitBtn.disabled = true;
    submitBtn.textContent = 'Signing in…';
  }

  try {
    const res = await apiRequest('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    });

    const user = res?.data?.user || res?.user;
    const token = res?.data?.token || res?.token;

    if (!token || !user) {
      throw new Error('Unexpected authentication response from server.');
    }

    if (user.role !== 'admin') {
      throw new Error('Access denied: Administrator privileges are required for Curator Portal.');
    }

    saveSession(token, user);
    renderApp();
    await bootstrapDashboard();
  } catch (err) {
    state.loginError = err.message || 'Sign in failed.';
    updateLoginError();
  } finally {
    state.loginLoading = false;
    const btn = document.getElementById('login-submit-btn');
    if (btn) {
      btn.disabled = false;
      btn.textContent = 'Sign In as Curator';
    }
  }
}

function mountDashboardShell() {
  const app = document.getElementById('app');
  const email = state.user?.email || 'curator@nortebound.ph';

  app.innerHTML = `
    <header class="topbar">
      <div class="topbar__inner">
        <div class="topbar__brand">
          <div class="brand-mark" aria-hidden="true">NB</div>
          <div>
            <h1 class="topbar__title">NORTE BOUND</h1>
            <p class="topbar__subtitle">Curator Admin Portal · Ilocos Norte</p>
          </div>
        </div>
        <div class="topbar__actions">
          <div id="api-health-pill" class="topbar-chip"></div>
          <div class="topbar-chip topbar-chip--email">Curator: ${escapeHtml(email)}</div>
          <button type="button" id="signout-btn" class="topbar-signout">Sign Out</button>
        </div>
      </div>
    </header>

    <main class="main-wrap">
      <section class="page-header">
        <div>
          <h2 class="page-header__title">Destination Registry</h2>
          <p class="page-header__subtitle">
            Verify coordinates, entrance fees, schedules, and Hidden Gem dispersal coverage before places reach travelers.
          </p>
        </div>
        <div class="page-header__actions">
          <button type="button" id="refresh-btn" class="btn btn-secondary">Refresh</button>
          <button type="button" id="add-dest-btn" class="btn btn-primary">+ Add Destination</button>
        </div>
      </section>

      <section id="kpi-strip" class="kpi-grid" aria-label="Registry summary"></section>

      <section class="toolbar-card" aria-label="Destination filters">
        <div class="toolbar-row">
          <div class="toolbar-filters">
            <div class="search-box">
              <svg class="search-box__icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
                <circle cx="11" cy="11" r="8"></circle>
                <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
              </svg>
              <label for="filter-search" class="sr-only">Search destinations</label>
              <input
                type="search"
                id="filter-search"
                class="input"
                placeholder="Search name, LGU, address, or tag…"
                value="${escapeHtml(state.filter.search)}"
              />
              <button
                type="button"
                id="clear-search-btn"
                class="search-box__clear"
                aria-label="Clear search"
                hidden
              >✕</button>
            </div>

            <div>
              <label for="filter-cluster" class="sr-only">Filter by cluster</label>
              <select id="filter-cluster" class="select">
                <option value="">All Clusters</option>
              </select>
            </div>

            <div>
              <label for="filter-lgu" class="sr-only">Filter by LGU</label>
              <select id="filter-lgu" class="select">
                <option value="">All LGUs</option>
              </select>
            </div>

            <div>
              <label for="filter-category" class="sr-only">Filter by category</label>
              <select id="filter-category" class="select">
                <option value="">All Categories</option>
              </select>
            </div>

            <div>
              <label for="filter-status" class="sr-only">Filter by verification status</label>
              <select id="filter-status" class="select">
                <option value="">All Verification</option>
                <option value="verified">Verified</option>
                <option value="needs_field_verification">Needs Field Check</option>
              </select>
            </div>
          </div>

          <div class="segmented" role="group" aria-label="Display layout">
            <button
              type="button"
              id="view-table-btn"
              class="segmented__btn${state.viewMode === 'table' ? ' is-active' : ''}"
              aria-pressed="${state.viewMode === 'table'}"
            >Table</button>
            <button
              type="button"
              id="view-grid-btn"
              class="segmented__btn${state.viewMode === 'grid' ? ' is-active' : ''}"
              aria-pressed="${state.viewMode === 'grid'}"
            >Photo Grid</button>
          </div>
        </div>

        <div class="toolbar-meta">
          <div class="toolbar-meta__left">
            <span id="filter-count-label" class="num">Loading destinations…</span>
            <button type="button" id="clear-filters-btn" class="btn btn-ghost btn-sm" hidden>Clear filters</button>
          </div>
          <span class="num">Source of truth: Supabase PostgreSQL</span>
        </div>
      </section>

      <section id="catalog-region" aria-live="polite"></section>
    </main>

    <div id="modal-root"></div>
  `;

  updateHealthBadge();

  document.getElementById('signout-btn')?.addEventListener('click', () => {
    clearSession();
    renderApp();
  });

  document.getElementById('refresh-btn')?.addEventListener('click', () => {
    loadDestinations();
  });

  document.getElementById('add-dest-btn')?.addEventListener('click', () => {
    openCreateModal();
  });

  const searchInput = document.getElementById('filter-search');
  const clearSearchBtn = document.getElementById('clear-search-btn');
  searchInput?.addEventListener('input', (e) => {
    state.filter.search = e.target.value;
    if (clearSearchBtn) {
      clearSearchBtn.hidden = !state.filter.search;
    }
    renderKpiAndCatalog();
  });

  clearSearchBtn?.addEventListener('click', () => {
    state.filter.search = '';
    if (searchInput) searchInput.value = '';
    clearSearchBtn.hidden = true;
    searchInput?.focus();
    renderKpiAndCatalog();
  });

  document.getElementById('filter-cluster')?.addEventListener('change', (e) => {
    state.filter.cluster = e.target.value;
    if (state.filter.lgu) {
      const selectedLgu = state.lgus.find((l) => l.code === state.filter.lgu);
      if (state.filter.cluster && selectedLgu && selectedLgu.cluster !== state.filter.cluster) {
        state.filter.lgu = '';
        const lguSelect = document.getElementById('filter-lgu');
        if (lguSelect) lguSelect.value = '';
      }
    }
    populateFilterDropdowns();
    renderKpiAndCatalog();
  });

  document.getElementById('filter-lgu')?.addEventListener('change', (e) => {
    state.filter.lgu = e.target.value;
    renderKpiAndCatalog();
  });

  document.getElementById('filter-category')?.addEventListener('change', (e) => {
    state.filter.category = e.target.value;
    renderKpiAndCatalog();
  });

  document.getElementById('filter-status')?.addEventListener('change', (e) => {
    state.filter.status = e.target.value;
    renderKpiAndCatalog();
  });

  document.getElementById('clear-filters-btn')?.addEventListener('click', () => {
    clearAllFilters();
  });

  const tableBtn = document.getElementById('view-table-btn');
  const gridBtn = document.getElementById('view-grid-btn');
  tableBtn?.addEventListener('click', () => setViewMode('table'));
  gridBtn?.addEventListener('click', () => setViewMode('grid'));

  document.getElementById('catalog-region')?.addEventListener('click', handleCatalogAction);
}

function clearAllFilters() {
  state.filter = { search: '', cluster: '', lgu: '', category: '', status: '' };
  const ids = [
    ['filter-search', ''],
    ['filter-cluster', ''],
    ['filter-lgu', ''],
    ['filter-category', ''],
    ['filter-status', ''],
  ];
  for (const [id, val] of ids) {
    const el = document.getElementById(id);
    if (el) el.value = val;
  }
  const clearSearchBtn = document.getElementById('clear-search-btn');
  if (clearSearchBtn) clearSearchBtn.hidden = true;
  populateFilterDropdowns();
  renderKpiAndCatalog();
}

function setViewMode(mode) {
  state.viewMode = mode;
  localStorage.setItem('nb_admin_view', mode);
  const tableBtn = document.getElementById('view-table-btn');
  const gridBtn = document.getElementById('view-grid-btn');
  if (tableBtn) {
    tableBtn.classList.toggle('is-active', mode === 'table');
    tableBtn.setAttribute('aria-pressed', String(mode === 'table'));
  }
  if (gridBtn) {
    gridBtn.classList.toggle('is-active', mode === 'grid');
    gridBtn.setAttribute('aria-pressed', String(mode === 'grid'));
  }
  renderKpiAndCatalog();
}

function populateFilterDropdowns() {
  const clusterEl = document.getElementById('filter-cluster');
  const lguEl = document.getElementById('filter-lgu');
  const catEl = document.getElementById('filter-category');

  if (clusterEl) {
    const opts = state.clusters
      .map(
        (c) =>
          `<option value="${escapeHtml(c.cluster)}"${state.filter.cluster === c.cluster ? ' selected' : ''}>${escapeHtml(c.label)} (${c.total})</option>`,
      )
      .join('');
    clusterEl.innerHTML = `<option value="">All Clusters (${state.clusters.length || 4})</option>${opts}`;
  }

  if (lguEl) {
    const visibleLgus = state.filter.cluster
      ? state.lgus.filter((l) => l.cluster === state.filter.cluster)
      : state.lgus;
    const opts = visibleLgus
      .map(
        (l) =>
          `<option value="${escapeHtml(l.code)}"${state.filter.lgu === l.code ? ' selected' : ''}>${escapeHtml(l.name)} (${escapeHtml(l.type)})</option>`,
      )
      .join('');
    lguEl.innerHTML = `<option value="">All ${visibleLgus.length} LGUs</option>${opts}`;
  }

  if (catEl) {
    const opts = state.categories
      .map(
        (c) =>
          `<option value="${escapeHtml(c.code)}"${state.filter.category === c.code ? ' selected' : ''}>${escapeHtml(c.name)}</option>`,
      )
      .join('');
    catEl.innerHTML = `<option value="">All Categories</option>${opts}`;
  }
}

function renderKpiAndCatalog() {
  renderKpiStrip();
  renderCatalog();
}

function renderKpiStrip() {
  const container = document.getElementById('kpi-strip');
  if (!container) return;

  const total = state.destinations.length;
  const verified = state.destinations.filter((d) => d.verification?.status === 'verified').length;
  const pending = total - verified;
  const hiddenGems = state.destinations.filter(
    (d) => d.popularityTier === 'hidden_gem' || d.isCommunityBased,
  ).length;
  const hiddenPct = total > 0 ? Math.round((hiddenGems / total) * 100) : 0;
  const verifiedPct = total > 0 ? Math.round((verified / total) * 100) : 0;
  const coveredLgus = new Set(state.destinations.map((d) => d.lgu?.code).filter(Boolean)).size;
  const lguDenom = state.lguTotal || state.lgus.length || 22;

  container.innerHTML = `
    <article class="kpi-card">
      <p class="kpi-card__label">Total Places</p>
      <p class="kpi-card__value num">${total}</p>
      <p class="kpi-card__meta">Across ${escapeHtml(state.clusters.length || 4)} provincial clusters</p>
    </article>

    <article class="kpi-card">
      <p class="kpi-card__label">Verified</p>
      <p class="kpi-card__value kpi-card__value--verified num">${verified}</p>
      <p class="kpi-card__meta num">${verifiedPct}% field-confirmed</p>
    </article>

    <article class="kpi-card">
      <p class="kpi-card__label">Pending Check</p>
      <p class="kpi-card__value num">${pending}</p>
      <p class="kpi-card__meta">${pending === 0 ? 'All entries audited' : 'Awaiting curator verification'}</p>
    </article>

    <article class="kpi-card">
      <p class="kpi-card__label">Hidden Gem Dispersal</p>
      <p class="kpi-card__value kpi-card__value--accent num">${hiddenPct}%</p>
      <p class="kpi-card__meta num">${hiddenGems} off-center places · target &ge;30%</p>
    </article>

    <article class="kpi-card">
      <p class="kpi-card__label">LGUs Covered</p>
      <p class="kpi-card__value num">${coveredLgus} / ${lguDenom}</p>
      <p class="kpi-card__meta">Province-wide representation</p>
    </article>
  `;
}

function renderThumbHtml(d) {
  const initials = escapeHtml(getInitials(d.name));
  if (!d.imageUrl) {
    return `<div class="thumb">${initials}</div>`;
  }
  return `
    <div class="thumb">
      <img
        src="${escapeHtml(d.imageUrl)}"
        alt="${escapeHtml(d.name)}"
        loading="lazy"
        onerror="this.style.display='none';this.nextElementSibling.style.display='flex';"
      />
      <span style="display:none;align-items:center;justify-content:center;width:100%;height:100%;">${initials}</span>
    </div>
  `;
}

function renderTierPill(tier) {
  const label = POPULARITY_TIER_LABELS[tier] || 'Moderate';
  const cls = tier === 'hidden_gem' ? 'pill pill-gem' : 'pill pill-forest';
  return `<span class="${cls}">${escapeHtml(label)}</span>`;
}

function renderStatusToggleButton(d) {
  const isVerified = d.verification?.status === 'verified';
  const isBusy = state.pendingStatusIds.has(d.id);
  return `
    <button
      type="button"
      class="pill status-toggle ${isVerified ? 'pill-verified' : 'pill-pending'}"
      data-action="toggle-status"
      data-id="${d.id}"
      ${isBusy ? 'disabled' : ''}
      title="Click to toggle verification status"
    >
      ${isBusy ? 'Updating…' : isVerified ? '✓ Verified' : 'Needs Check'}
    </button>
  `;
}

function renderCatalog() {
  const region = document.getElementById('catalog-region');
  const countLabel = document.getElementById('filter-count-label');
  const clearBtn = document.getElementById('clear-filters-btn');
  if (!region) return;

  const hasActiveFilter = Boolean(
    state.filter.search.trim()
      || state.filter.cluster
      || state.filter.lgu
      || state.filter.category
      || state.filter.status,
  );

  if (clearBtn) {
    clearBtn.hidden = !hasActiveFilter;
  }

  if (state.loading && state.destinations.length === 0) {
    if (countLabel) countLabel.textContent = 'Loading destinations…';
    region.innerHTML = `
      <div class="empty-state">
        <p class="empty-state__title">Loading Ilocos Norte registry…</p>
        <p class="empty-state__copy">Fetching verified destinations, LGUs, and taxonomy metadata.</p>
      </div>
    `;
    return;
  }

  const filtered = getFilteredDestinations();
  if (countLabel) {
    countLabel.textContent = `Showing ${filtered.length} of ${state.destinations.length} places`;
  }

  if (filtered.length === 0) {
    region.innerHTML = `
      <div class="empty-state">
        <p class="empty-state__title">No places match the current filters</p>
        <p class="empty-state__copy">Adjust your search term, LGU, category, or verification filter to view entries.</p>
        ${hasActiveFilter ? '<button type="button" class="btn btn-secondary btn-sm" data-action="clear-filters">Reset all filters</button>' : ''}
      </div>
    `;
    return;
  }

  if (state.viewMode === 'grid') {
    region.innerHTML = `<div class="photo-grid">${filtered.map(renderPhotoCard).join('')}</div>`;
    return;
  }

  region.innerHTML = `
    <div class="surface-card">
      <div class="table-scroll">
        <table class="data-table">
          <thead>
            <tr>
              <th>Place</th>
              <th>LGU &amp; Cluster</th>
              <th>Category</th>
              <th>Tier &amp; Fee</th>
              <th>Verification</th>
              <th style="text-align:right;">Actions</th>
            </tr>
          </thead>
          <tbody>
            ${filtered.map(renderTableRow).join('')}
          </tbody>
        </table>
      </div>
    </div>
  `;
}

function renderTableRow(d) {
  const lguName = d.lgu?.name || d.lgu?.code || '—';
  const clusterName = humanizeCluster(d.lgu?.cluster);
  const categoryName = d.category?.name || d.category?.code || '—';
  const feeText = d.pricing?.isFree
    ? 'Free entry'
    : `${formatPhp(d.pricing?.entranceFeeAdult)} adult`;
  const lastVerified = d.verification?.lastVerifiedDate
    ? `Verified ${escapeHtml(d.verification.lastVerifiedDate)}`
    : 'No audit date';

  return `
    <tr>
      <td>
        <div class="place-cell">
          ${renderThumbHtml(d)}
          <div>
            <div class="place-cell__name">${escapeHtml(d.name)}</div>
            <div class="place-cell__sub" title="${escapeHtml(d.address)}">${escapeHtml(d.slug)} · ${escapeHtml(d.address)}</div>
          </div>
        </div>
      </td>
      <td>
        <div class="lgu-cell__name">${escapeHtml(lguName)}</div>
        <div class="lgu-cell__cluster">${escapeHtml(clusterName)}</div>
      </td>
      <td>
        <span class="pill pill-sky">${escapeHtml(categoryName)}</span>
      </td>
      <td>
        <div class="tier-stack">
          ${renderTierPill(d.popularityTier)}
          <span class="fee-text num">${escapeHtml(feeText)}</span>
        </div>
      </td>
      <td>
        <div class="status-stack">
          ${renderStatusToggleButton(d)}
          <span class="verified-meta num">${lastVerified}</span>
        </div>
      </td>
      <td style="text-align:right;">
        <div class="row-actions">
          <button type="button" class="btn btn-secondary btn-sm" data-action="edit" data-id="${d.id}" data-slug="${escapeHtml(d.slug)}">Edit</button>
          <button type="button" class="btn btn-danger-soft btn-sm" data-action="delete" data-id="${d.id}">Delete</button>
        </div>
      </td>
    </tr>
  `;
}

function renderPhotoCard(d) {
  const lguName = d.lgu?.name || d.lgu?.code || '—';
  const categoryName = d.category?.name || d.category?.code || '—';
  const feeText = d.pricing?.isFree ? 'Free' : formatPhp(d.pricing?.entranceFeeAdult);
  const initials = escapeHtml(getInitials(d.name));

  return `
    <article class="dest-card">
      <div class="dest-card__media">
        ${
          d.imageUrl
            ? `
              <img
                src="${escapeHtml(d.imageUrl)}"
                alt="${escapeHtml(d.name)}"
                loading="lazy"
                onerror="this.style.display='none';this.nextElementSibling.style.display='flex';"
              />
              <div class="dest-card__fallback" style="display:none;">${initials}</div>
            `
            : `<div class="dest-card__fallback">${initials}</div>`
        }
      </div>
      <div class="dest-card__body">
        <div class="dest-card__pills">
          <span class="pill pill-sky">${escapeHtml(categoryName)}</span>
          ${renderTierPill(d.popularityTier)}
        </div>
        <h3 class="dest-card__title">${escapeHtml(d.name)}</h3>
        <p class="dest-card__meta">${escapeHtml(lguName)} · <span class="num">${escapeHtml(feeText)}</span></p>
        <div class="dest-card__footer">
          ${renderStatusToggleButton(d)}
          <div class="row-actions">
            <button type="button" class="btn btn-secondary btn-sm" data-action="edit" data-id="${d.id}" data-slug="${escapeHtml(d.slug)}">Edit</button>
            <button type="button" class="btn btn-danger-soft btn-sm" data-action="delete" data-id="${d.id}">Delete</button>
          </div>
        </div>
      </div>
    </article>
  `;
}

async function handleCatalogAction(event) {
  const btn = event.target.closest('[data-action]');
  if (!btn) return;

  const action = btn.dataset.action;
  if (action === 'clear-filters') {
    clearAllFilters();
    return;
  }

  const id = Number(btn.dataset.id);
  const dest = state.destinations.find((item) => item.id === id);
  if (!dest) return;

  if (action === 'toggle-status') {
    await toggleVerificationStatus(dest);
    return;
  }

  if (action === 'edit') {
    await openEditModal(dest, btn);
    return;
  }

  if (action === 'delete') {
    openDeleteModal(dest);
  }
}

async function toggleVerificationStatus(dest) {
  const currentStatus = dest.verification?.status;
  const nextStatus = currentStatus === 'verified'
    ? 'needs_field_verification'
    : 'verified';

  state.pendingStatusIds.add(dest.id);
  renderCatalog();

  try {
    const res = await apiRequest(`/admin/destinations/${dest.id}/status`, {
      method: 'PATCH',
      body: JSON.stringify({ verification_status: nextStatus }),
    });

    const updated = res?.data;
    if (updated) {
      const idx = state.destinations.findIndex((item) => item.id === dest.id);
      if (idx !== -1) {
        state.destinations[idx] = {
          ...state.destinations[idx],
          verification: updated.verification || {
            ...state.destinations[idx].verification,
            status: nextStatus,
          },
        };
      }
    }
    showToast(
      nextStatus === 'verified'
        ? `Marked "${dest.name}" as verified.`
        : `Flagged "${dest.name}" for field check.`,
    );
  } catch (err) {
    showToast(err.message || 'Unable to update verification status.', 'error');
  } finally {
    state.pendingStatusIds.delete(dest.id);
    renderKpiAndCatalog();
  }
}

function buildDefaultHours(existingSlots = []) {
  const byDay = new Map();
  for (const slot of existingSlots || []) {
    const day = Number(slot.dayOfWeek ?? slot.day_of_week);
    if (Number.isInteger(day) && day >= 0 && day <= 6) {
      byDay.set(day, slot);
    }
  }

  return DAY_NAMES.map((_, dayOfWeek) => {
    const found = byDay.get(dayOfWeek);
    if (found) {
      const is24 = Boolean(found.is24Hours ?? found.is_24_hours);
      const closed = Boolean(found.temporarilyClosed ?? found.temporarily_closed);
      return {
        day_of_week: dayOfWeek,
        opening_time: is24 || closed ? '' : (found.openingTime ?? found.opening_time ?? '08:00') || '08:00',
        closing_time: is24 || closed ? '' : (found.closingTime ?? found.closing_time ?? '17:00') || '17:00',
        is_24_hours: is24,
        temporarily_closed: closed,
      };
    }

    return {
      day_of_week: dayOfWeek,
      opening_time: '08:00',
      closing_time: '17:00',
      is_24_hours: false,
      temporarily_closed: false,
    };
  });
}

function openCreateModal() {
  const defaultLgu = state.lgus[0]?.code || 'laoag-city';
  const defaultCategory = state.categories[0]?.code || 'heritage';

  state.modal = {
    mode: 'create',
    destinationId: null,
    slugTouched: false,
    saving: false,
    error: null,
    form: {
      name: '',
      slug: '',
      lgu_code: defaultLgu,
      category_code: defaultCategory,
      entity_type: 'attraction',
      popularity_tier: 'moderate',
      verification_status: 'verified',
      road_condition: 'paved_all_weather',
      highway_accessible: true,
      image_url: '',
      description: '',
      historical_background: '',
      address: '',
      latitude: 18.1987,
      longitude: 120.5936,
      source_name: '',
      source_type: 'lgu_official',
      pricing: {
        is_free: true,
        entrance_fee_adult: 0,
        entrance_fee_concession: 0,
        mandatory_activity_fee: 0,
        parking_fee: 0,
        estimated_meal_min: 0,
        estimated_meal_max: 0,
      },
      tags: [],
      operatingHours: buildDefaultHours(),
    },
  };
  renderDestinationModal();
}

async function openEditModal(summaryDest, triggerBtn) {
  const originalText = triggerBtn?.textContent;
  if (triggerBtn) {
    triggerBtn.disabled = true;
    triggerBtn.textContent = 'Loading…';
  }

  let detail = summaryDest;
  try {
    const res = await apiRequest(`/destinations/${encodeURIComponent(summaryDest.slug)}`);
    if (res?.data) {
      detail = res.data;
    }
  } catch (err) {
    showToast(`Loaded summary only (${err.message}).`, 'error');
  } finally {
    if (triggerBtn) {
      triggerBtn.disabled = false;
      triggerBtn.textContent = originalText || 'Edit';
    }
  }

  const p = detail.pricing || {};
  state.modal = {
    mode: 'edit',
    destinationId: detail.id,
    slugTouched: true,
    saving: false,
    error: null,
    form: {
      name: detail.name || '',
      slug: detail.slug || '',
      lgu_code: detail.lgu?.code || '',
      category_code: detail.category?.code || '',
      entity_type: detail.entityType || 'attraction',
      popularity_tier: detail.popularityTier || 'moderate',
      verification_status: detail.verification?.status || 'needs_field_verification',
      road_condition: detail.roadCondition || 'paved_all_weather',
      highway_accessible: Boolean(detail.highwayAccessible),
      image_url: detail.imageUrl || '',
      description: detail.description || '',
      historical_background: detail.historicalBackground || '',
      address: detail.address || '',
      latitude: detail.coordinates?.latitude ?? 18.1987,
      longitude: detail.coordinates?.longitude ?? 120.5936,
      source_name: detail.verification?.sourceName || '',
      source_type: detail.verification?.sourceType || '',
      pricing: {
        is_free: Boolean(p.isFree),
        entrance_fee_adult: Number(p.entranceFeeAdult || 0),
        entrance_fee_concession: Number(p.entranceFeeConcession || 0),
        mandatory_activity_fee: Number(p.mandatoryActivityFee || 0),
        parking_fee: Number(p.parkingFee || 0),
        estimated_meal_min: Number(p.estimatedMealMin || 0),
        estimated_meal_max: Number(p.estimatedMealMax || 0),
      },
      tags: Array.isArray(detail.tags) ? detail.tags.map((t) => t.slug).filter(Boolean) : [],
      operatingHours: buildDefaultHours(detail.operatingHours),
    },
  };

  renderDestinationModal();
}

function closeModal() {
  state.modal = null;
  state.deleteModal = null;
  const root = document.getElementById('modal-root');
  if (root) root.innerHTML = '';
}

function renderLguOptionsHtml(selectedCode) {
  if (state.clusters.length === 0) {
    return state.lgus
      .map(
        (l) =>
          `<option value="${escapeHtml(l.code)}"${l.code === selectedCode ? ' selected' : ''}>${escapeHtml(l.name)}</option>`,
      )
      .join('');
  }

  return state.clusters
    .map((group) => {
      const options = (group.lgus || [])
        .map(
          (l) =>
            `<option value="${escapeHtml(l.code)}"${l.code === selectedCode ? ' selected' : ''}>${escapeHtml(l.name)} (${escapeHtml(l.type)})</option>`,
        )
        .join('');
      return `<optgroup label="${escapeHtml(group.label)}">${options}</optgroup>`;
    })
    .join('');
}

function renderOptionList(optionsMap, selected) {
  return Object.entries(optionsMap)
    .map(
      ([value, label]) =>
        `<option value="${escapeHtml(value)}"${value === selected ? ' selected' : ''}>${escapeHtml(label)}</option>`,
    )
    .join('');
}

function renderHoursRowsHtml(hours) {
  return hours
    .map((slot) => {
      const disabledTimes = slot.is_24_hours || slot.temporarily_closed;
      return `
        <div class="hours-row" data-day="${slot.day_of_week}">
          <span class="hours-day">${DAY_NAMES[slot.day_of_week]}</span>
          <input
            type="time"
            class="input num"
            data-hour-field="opening_time"
            data-day="${slot.day_of_week}"
            value="${escapeHtml(slot.opening_time || '08:00')}"
            ${disabledTimes ? 'disabled' : ''}
            aria-label="${DAY_NAMES[slot.day_of_week]} opening time"
          />
          <input
            type="time"
            class="input num"
            data-hour-field="closing_time"
            data-day="${slot.day_of_week}"
            value="${escapeHtml(slot.closing_time || '17:00')}"
            ${disabledTimes ? 'disabled' : ''}
            aria-label="${DAY_NAMES[slot.day_of_week]} closing time"
          />
          <label class="check-row" style="font-size:12px;">
            <input
              type="checkbox"
              data-hour-field="is_24_hours"
              data-day="${slot.day_of_week}"
              ${slot.is_24_hours ? 'checked' : ''}
            />
            <span>24h</span>
          </label>
          <label class="check-row" style="font-size:12px;">
            <input
              type="checkbox"
              data-hour-field="temporarily_closed"
              data-day="${slot.day_of_week}"
              ${slot.temporarily_closed ? 'checked' : ''}
            />
            <span>Closed</span>
          </label>
        </div>
      `;
    })
    .join('');
}

function renderDestinationModal() {
  const root = document.getElementById('modal-root');
  if (!root || !state.modal) return;

  const { mode, form, saving, error } = state.modal;
  const isEdit = mode === 'edit';
  const selectedTags = new Set(form.tags);

  root.innerHTML = `
    <div class="modal-backdrop" id="modal-backdrop">
      <div
        class="modal-dialog"
        role="dialog"
        aria-modal="true"
        aria-labelledby="dest-modal-title"
      >
        <div class="modal-header">
          <div>
            <h2 id="dest-modal-title" class="modal-title">${isEdit ? 'Edit Destination' : 'Add Destination'}</h2>
            <p class="modal-subtitle">
              ${isEdit ? `Record #${state.modal.destinationId} · ${escapeHtml(form.slug)}` : 'All entries require valid Ilocos Norte coordinates and grounded metadata.'}
            </p>
          </div>
          <button type="button" id="modal-close-btn" class="modal-close" aria-label="Close modal">✕</button>
        </div>

        <form id="destination-form" class="modal-form" novalidate>
          <div class="modal-body">
            ${
              error
                ? `<div class="alert alert-danger" role="alert"><span>${escapeHtml(error)}</span></div>`
                : ''
            }

            <div class="form-section">
              <div class="form-section__head">
                <h3 class="form-section__title">Identity &amp; Photo</h3>
              </div>

              <div class="grid-2">
                <div class="field">
                  <label for="f-name" class="field-label">Destination Name *</label>
                  <input type="text" id="f-name" name="name" class="input" required maxlength="200" value="${escapeHtml(form.name)}" />
                </div>
                <div class="field">
                  <label for="f-slug" class="field-label">URL Slug *</label>
                  <input
                    type="text"
                    id="f-slug"
                    name="slug"
                    class="input num"
                    required
                    maxlength="191"
                    pattern="^[a-z0-9]+(?:-[a-z0-9]+)*$"
                    placeholder="e.g. paoay-sand-dunes"
                    value="${escapeHtml(form.slug)}"
                  />
                </div>
              </div>

              <div class="photo-input-row">
                <div class="field">
                  <label for="f-image-url" class="field-label">Photo URL (Wikimedia / Verified HTTPS)</label>
                  <input
                    type="url"
                    id="f-image-url"
                    name="image_url"
                    class="input"
                    maxlength="1000"
                    placeholder="https://thumb.wikimedia.org/..."
                    value="${escapeHtml(form.image_url)}"
                  />
                  <span class="field-hint">Shown across Explore cards, Planner previews, and Curator Portal.</span>
                </div>
                <div id="photo-preview-box" class="photo-preview">
                  ${
                    form.image_url
                      ? `<img src="${escapeHtml(form.image_url)}" alt="Preview" onerror="this.parentElement.textContent='Invalid URL';" />`
                      : 'No photo'
                  }
                </div>
              </div>
            </div>

            <div class="form-section">
              <div class="form-section__head">
                <h3 class="form-section__title">Taxonomy &amp; Road Access</h3>
              </div>

              <div class="grid-3">
                <div class="field">
                  <label for="f-lgu" class="field-label">LGU *</label>
                  <select id="f-lgu" name="lgu_code" class="select" required>
                    ${renderLguOptionsHtml(form.lgu_code)}
                  </select>
                </div>
                <div class="field">
                  <label for="f-category" class="field-label">Category *</label>
                  <select id="f-category" name="category_code" class="select" required>
                    ${state.categories
                      .map(
                        (c) =>
                          `<option value="${escapeHtml(c.code)}"${c.code === form.category_code ? ' selected' : ''}>${escapeHtml(c.name)}</option>`,
                      )
                      .join('')}
                  </select>
                </div>
                <div class="field">
                  <label for="f-entity-type" class="field-label">Entity Type *</label>
                  <select id="f-entity-type" name="entity_type" class="select" required>
                    ${renderOptionList(ENTITY_TYPE_LABELS, form.entity_type)}
                  </select>
                </div>
              </div>

              <div class="grid-3">
                <div class="field">
                  <label for="f-tier" class="field-label">Popularity Tier *</label>
                  <select id="f-tier" name="popularity_tier" class="select" required>
                    ${renderOptionList(POPULARITY_TIER_LABELS, form.popularity_tier)}
                  </select>
                </div>
                <div class="field">
                  <label for="f-road" class="field-label">Road Condition *</label>
                  <select id="f-road" name="road_condition" class="select" required>
                    ${renderOptionList(ROAD_CONDITION_LABELS, form.road_condition)}
                  </select>
                </div>
                <div class="field" style="justify-content:flex-end;padding-bottom:6px;">
                  <label class="check-row">
                    <input type="checkbox" name="highway_accessible" ${form.highway_accessible ? 'checked' : ''} />
                    <span>Highway Accessible</span>
                  </label>
                </div>
              </div>
            </div>

            <div class="form-section">
              <div class="form-section__head">
                <h3 class="form-section__title">Description &amp; Coordinates</h3>
              </div>

              <div class="field">
                <label for="f-description" class="field-label">Traveler Description *</label>
                <textarea id="f-description" name="description" class="textarea" required maxlength="10000">${escapeHtml(form.description)}</textarea>
              </div>

              <div class="field">
                <label for="f-history" class="field-label">Historical / Cultural Context</label>
                <textarea id="f-history" name="historical_background" class="textarea" rows="2" maxlength="10000">${escapeHtml(form.historical_background)}</textarea>
              </div>

              <div class="grid-3">
                <div class="field">
                  <label for="f-address" class="field-label">Street / Barangay Address *</label>
                  <input type="text" id="f-address" name="address" class="input" required maxlength="255" value="${escapeHtml(form.address)}" />
                </div>
                <div class="field">
                  <label for="f-lat" class="field-label">Latitude (17.80 – 18.68) *</label>
                  <input type="number" id="f-lat" name="latitude" class="input num" step="any" min="17.8" max="18.68" required value="${escapeHtml(form.latitude)}" />
                </div>
                <div class="field">
                  <label for="f-lng" class="field-label">Longitude (120.40 – 121.05) *</label>
                  <input type="number" id="f-lng" name="longitude" class="input num" step="any" min="120.4" max="121.05" required value="${escapeHtml(form.longitude)}" />
                </div>
              </div>
            </div>

            <div class="form-section">
              <div class="form-section__head">
                <h3 class="form-section__title">Verified Pricing (PHP)</h3>
                <label class="check-row">
                  <input type="checkbox" name="is_free" ${form.pricing.is_free ? 'checked' : ''} />
                  <span>Free Admission</span>
                </label>
              </div>

              <div class="grid-3">
                <div class="field">
                  <label for="f-fee-adult" class="field-label">Adult Entrance (₱)</label>
                  <input type="number" id="f-fee-adult" name="entrance_fee_adult" class="input num" step="0.01" min="0" value="${escapeHtml(form.pricing.entrance_fee_adult)}" />
                </div>
                <div class="field">
                  <label for="f-fee-concession" class="field-label">Student / Senior (₱)</label>
                  <input type="number" id="f-fee-concession" name="entrance_fee_concession" class="input num" step="0.01" min="0" value="${escapeHtml(form.pricing.entrance_fee_concession)}" />
                </div>
                <div class="field">
                  <label for="f-fee-activity" class="field-label">Mandatory Activity Fee (₱)</label>
                  <input type="number" id="f-fee-activity" name="mandatory_activity_fee" class="input num" step="0.01" min="0" value="${escapeHtml(form.pricing.mandatory_activity_fee)}" />
                </div>
                <div class="field">
                  <label for="f-fee-parking" class="field-label">Parking Fee (₱)</label>
                  <input type="number" id="f-fee-parking" name="parking_fee" class="input num" step="0.01" min="0" value="${escapeHtml(form.pricing.parking_fee)}" />
                </div>
                <div class="field">
                  <label for="f-meal-min" class="field-label">Estimated Meal Min (₱)</label>
                  <input type="number" id="f-meal-min" name="estimated_meal_min" class="input num" step="0.01" min="0" value="${escapeHtml(form.pricing.estimated_meal_min)}" />
                </div>
                <div class="field">
                  <label for="f-meal-max" class="field-label">Estimated Meal Max (₱)</label>
                  <input type="number" id="f-meal-max" name="estimated_meal_max" class="input num" step="0.01" min="0" value="${escapeHtml(form.pricing.estimated_meal_max)}" />
                </div>
              </div>
            </div>

            <div class="form-section">
              <div class="form-section__head">
                <h3 class="form-section__title">Verification Provenance</h3>
              </div>

              <div class="grid-3">
                <div class="field">
                  <label for="f-verif-status" class="field-label">Verification Status *</label>
                  <select id="f-verif-status" name="verification_status" class="select" required>
                    <option value="verified"${form.verification_status === 'verified' ? ' selected' : ''}>Verified</option>
                    <option value="needs_field_verification"${form.verification_status === 'needs_field_verification' ? ' selected' : ''}>Needs Field Verification</option>
                  </select>
                </div>
                <div class="field">
                  <label for="f-source-type" class="field-label">Source Type</label>
                  <select id="f-source-type" name="source_type" class="select">
                    <option value="">Unspecified</option>
                    ${renderOptionList(SOURCE_TYPE_LABELS, form.source_type)}
                  </select>
                </div>
                <div class="field">
                  <label for="f-source-name" class="field-label">Source / Office Name</label>
                  <input type="text" id="f-source-name" name="source_name" class="input" maxlength="255" placeholder="e.g. Ilocos Norte Tourism Office" value="${escapeHtml(form.source_name)}" />
                </div>
              </div>
            </div>

            <div class="form-section">
              <div class="form-section__head">
                <h3 class="form-section__title">Interest Tags (<span id="selected-tags-count" class="num">${selectedTags.size}</span>)</h3>
                <span class="field-hint">Used for deterministic recommendation scoring</span>
              </div>
              <div id="modal-tag-cloud" class="tag-cloud">
                ${state.interestTags
                  .map(
                    (tag) => `
                      <button
                        type="button"
                        class="tag-chip"
                        data-tag-slug="${escapeHtml(tag.slug)}"
                        aria-pressed="${selectedTags.has(tag.slug)}"
                      >${escapeHtml(tag.name)}</button>
                    `,
                  )
                  .join('')}
              </div>
            </div>

            <div class="form-section">
              <div class="form-section__head">
                <h3 class="form-section__title">Operating Hours &amp; Temporary Closures</h3>
                <div class="row-actions">
                  <button type="button" id="hours-standard-btn" class="btn btn-secondary btn-sm">08:00–17:00 Daily</button>
                  <button type="button" id="hours-close-week-btn" class="btn btn-secondary btn-sm">Toggle Closed All Week</button>
                </div>
              </div>
              <div id="modal-hours-list" class="hours-list">
                ${renderHoursRowsHtml(form.operatingHours)}
              </div>
            </div>
          </div>

          <div class="modal-footer">
            <button type="button" id="modal-cancel-btn" class="btn btn-secondary">Cancel</button>
            <button type="submit" id="modal-save-btn" class="btn btn-primary" ${saving ? 'disabled' : ''}>
              ${saving ? 'Saving…' : isEdit ? 'Save Changes' : 'Create Destination'}
            </button>
          </div>
        </form>
      </div>
    </div>
  `;

  document.getElementById('modal-close-btn')?.addEventListener('click', closeModal);
  document.getElementById('modal-cancel-btn')?.addEventListener('click', closeModal);
  document.getElementById('modal-backdrop')?.addEventListener('click', (e) => {
    if (e.target.id === 'modal-backdrop') closeModal();
  });

  const nameInput = document.getElementById('f-name');
  const slugInput = document.getElementById('f-slug');
  slugInput?.addEventListener('input', () => {
    if (state.modal) state.modal.slugTouched = true;
  });
  nameInput?.addEventListener('input', () => {
    if (state.modal && !state.modal.slugTouched && slugInput) {
      slugInput.value = slugify(nameInput.value);
    }
  });

  const imageInput = document.getElementById('f-image-url');
  const previewBox = document.getElementById('photo-preview-box');
  imageInput?.addEventListener('input', () => {
    const val = imageInput.value.trim();
    if (!previewBox) return;
    if (!val) {
      previewBox.textContent = 'No photo';
      return;
    }
    const img = document.createElement('img');
    img.src = val;
    img.alt = 'Preview';
    img.addEventListener('error', () => {
      previewBox.textContent = 'Invalid URL';
    });
    previewBox.innerHTML = '';
    previewBox.appendChild(img);
  });

  document.getElementById('modal-tag-cloud')?.addEventListener('click', (e) => {
    const chip = e.target.closest('[data-tag-slug]');
    if (!chip || !state.modal) return;
    const slug = chip.dataset.tagSlug;
    const tags = new Set(state.modal.form.tags);
    if (tags.has(slug)) {
      tags.delete(slug);
    } else {
      tags.add(slug);
    }
    state.modal.form.tags = Array.from(tags);
    chip.setAttribute('aria-pressed', String(tags.has(slug)));
    const countEl = document.getElementById('selected-tags-count');
    if (countEl) countEl.textContent = String(tags.size);
  });

  const hoursContainer = document.getElementById('modal-hours-list');
  hoursContainer?.addEventListener('change', (e) => {
    if (!state.modal) return;
    const input = e.target.closest('[data-hour-field]');
    if (!input) return;
    const day = Number(input.dataset.day);
    const field = input.dataset.hourField;
    const slot = state.modal.form.operatingHours[day];
    if (!slot) return;

    if (field === 'is_24_hours' || field === 'temporarily_closed') {
      slot[field] = input.checked;
      if (field === 'is_24_hours' && input.checked) {
        slot.temporarily_closed = false;
      }
      if (field === 'temporarily_closed' && input.checked) {
        slot.is_24_hours = false;
      }
      hoursContainer.innerHTML = renderHoursRowsHtml(state.modal.form.operatingHours);
    } else {
      slot[field] = input.value;
    }
  });

  document.getElementById('hours-standard-btn')?.addEventListener('click', () => {
    if (!state.modal || !hoursContainer) return;
    state.modal.form.operatingHours = buildDefaultHours();
    hoursContainer.innerHTML = renderHoursRowsHtml(state.modal.form.operatingHours);
  });

  document.getElementById('hours-close-week-btn')?.addEventListener('click', () => {
    if (!state.modal || !hoursContainer) return;
    const allClosed = state.modal.form.operatingHours.every((h) => h.temporarily_closed);
    state.modal.form.operatingHours = state.modal.form.operatingHours.map((h) => ({
      ...h,
      temporarily_closed: !allClosed,
      is_24_hours: false,
    }));
    hoursContainer.innerHTML = renderHoursRowsHtml(state.modal.form.operatingHours);
  });

  document.getElementById('destination-form')?.addEventListener('submit', handleSaveDestination);
  document.getElementById('f-name')?.focus();
}

async function handleSaveDestination(event) {
  event.preventDefault();
  if (!state.modal || state.modal.saving) return;

  const formEl = event.target;
  const fd = new FormData(formEl);

  const mealMin = Number(fd.get('estimated_meal_min') || 0);
  const mealMax = Number(fd.get('estimated_meal_max') || 0);
  if (mealMax < mealMin) {
    state.modal.error = 'Estimated meal max must be greater than or equal to estimated meal min.';
    renderDestinationModal();
    return;
  }

  const normalizedHours = state.modal.form.operatingHours.map((slot) => {
    if (slot.is_24_hours || slot.temporarily_closed) {
      return {
        day_of_week: slot.day_of_week,
        opening_time: null,
        closing_time: null,
        is_24_hours: Boolean(slot.is_24_hours),
        temporarily_closed: Boolean(slot.temporarily_closed),
      };
    }
    return {
      day_of_week: slot.day_of_week,
      opening_time: slot.opening_time ? slot.opening_time.slice(0, 5) : '08:00',
      closing_time: slot.closing_time ? slot.closing_time.slice(0, 5) : '17:00',
      is_24_hours: false,
      temporarily_closed: false,
    };
  });

  const sourceTypeRaw = String(fd.get('source_type') || '').trim();
  const payload = {
    name: String(fd.get('name') || '').trim(),
    slug: String(fd.get('slug') || '').trim(),
    lgu_code: String(fd.get('lgu_code') || '').trim(),
    category_code: String(fd.get('category_code') || '').trim(),
    description: String(fd.get('description') || '').trim(),
    historical_background: String(fd.get('historical_background') || '').trim() || null,
    address: String(fd.get('address') || '').trim(),
    latitude: Number(fd.get('latitude')),
    longitude: Number(fd.get('longitude')),
    image_url: String(fd.get('image_url') || '').trim() || null,
    entity_type: String(fd.get('entity_type') || 'attraction'),
    popularity_tier: String(fd.get('popularity_tier') || 'moderate'),
    verification_status: String(fd.get('verification_status') || 'needs_field_verification'),
    highway_accessible: fd.get('highway_accessible') === 'on',
    road_condition: String(fd.get('road_condition') || 'paved_all_weather'),
    source_name: String(fd.get('source_name') || '').trim() || null,
    source_type: sourceTypeRaw || null,
    tags: [...state.modal.form.tags],
    operatingHours: normalizedHours,
    pricing: {
      is_free: fd.get('is_free') === 'on',
      entrance_fee_adult: Number(fd.get('entrance_fee_adult') || 0),
      entrance_fee_concession: Number(fd.get('entrance_fee_concession') || 0),
      mandatory_activity_fee: Number(fd.get('mandatory_activity_fee') || 0),
      parking_fee: Number(fd.get('parking_fee') || 0),
      estimated_meal_min: mealMin,
      estimated_meal_max: mealMax,
      currency: 'PHP',
    },
  };

  state.modal.saving = true;
  state.modal.error = null;
  const saveBtn = document.getElementById('modal-save-btn');
  if (saveBtn) {
    saveBtn.disabled = true;
    saveBtn.textContent = 'Saving…';
  }

  try {
    const isEdit = state.modal.mode === 'edit';
    if (isEdit) {
      await apiRequest(`/admin/destinations/${state.modal.destinationId}`, {
        method: 'PUT',
        body: JSON.stringify(payload),
      });
      showToast(`Updated "${payload.name}".`);
    } else {
      await apiRequest('/admin/destinations', {
        method: 'POST',
        body: JSON.stringify(payload),
      });
      showToast(`Created "${payload.name}".`);
    }

    closeModal();
    await loadDestinations();
  } catch (err) {
    state.modal.saving = false;
    state.modal.error = err.message || 'Unable to save destination.';
    state.modal.form = {
      ...state.modal.form,
      ...payload,
      historical_background: payload.historical_background || '',
      image_url: payload.image_url || '',
      source_name: payload.source_name || '',
      source_type: payload.source_type || '',
    };
    renderDestinationModal();
  }
}

function openDeleteModal(dest) {
  state.deleteModal = dest;
  const root = document.getElementById('modal-root');
  if (!root) return;

  root.innerHTML = `
    <div class="modal-backdrop" id="delete-backdrop">
      <div class="modal-dialog modal-dialog--sm" role="dialog" aria-modal="true" aria-labelledby="delete-title">
        <div class="modal-header">
          <div>
            <h2 id="delete-title" class="modal-title">Delete Destination</h2>
            <p class="modal-subtitle num">${escapeHtml(dest.slug)}</p>
          </div>
          <button type="button" id="delete-close-btn" class="modal-close" aria-label="Close modal">✕</button>
        </div>
        <div class="modal-body">
          <p style="margin:0;font-size:14px;color:var(--forest-72);">
            Remove <strong>${escapeHtml(dest.name)}</strong> from the verified Ilocos Norte registry?
            This cannot be undone, and entries referenced by existing saved itineraries cannot be deleted.
          </p>
          <div id="delete-error-slot"></div>
        </div>
        <div class="modal-footer">
          <button type="button" id="delete-cancel-btn" class="btn btn-secondary">Cancel</button>
          <button type="button" id="delete-confirm-btn" class="btn btn-danger">Delete Record</button>
        </div>
      </div>
    </div>
  `;

  document.getElementById('delete-close-btn')?.addEventListener('click', closeModal);
  document.getElementById('delete-cancel-btn')?.addEventListener('click', closeModal);
  document.getElementById('delete-backdrop')?.addEventListener('click', (e) => {
    if (e.target.id === 'delete-backdrop') closeModal();
  });

  document.getElementById('delete-confirm-btn')?.addEventListener('click', async () => {
    const confirmBtn = document.getElementById('delete-confirm-btn');
    const errorSlot = document.getElementById('delete-error-slot');
    if (confirmBtn) {
      confirmBtn.disabled = true;
      confirmBtn.textContent = 'Deleting…';
    }
    try {
      await apiRequest(`/admin/destinations/${dest.id}`, { method: 'DELETE' });
      closeModal();
      showToast(`Deleted "${dest.name}".`);
      await loadDestinations();
    } catch (err) {
      if (confirmBtn) {
        confirmBtn.disabled = false;
        confirmBtn.textContent = 'Delete Record';
      }
      if (errorSlot) {
        errorSlot.innerHTML = `<div class="alert alert-danger" role="alert"><span>${escapeHtml(err.message)}</span></div>`;
      }
    }
  });
}

async function init() {
  renderApp();
  checkApiHealth();

  if (state.token && state.user?.role === 'admin') {
    await bootstrapDashboard();
  }
}

document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape' && (state.modal || state.deleteModal)) {
    closeModal();
  }
});

document.addEventListener('DOMContentLoaded', init);
