// NORTE BOUND Web Admin Portal Application Logic

const API_BASE_URL = 'http://localhost:5000/api/v1';

let state = {
    token: localStorage.getItem('nb_admin_token') || null,
    user: JSON.parse(localStorage.getItem('nb_admin_user') || 'null'),
    destinations: [],
    lgus: [],
    taxonomy: [],
    loading: false,
    error: null,
    success: null,
    filter: {
        search: '',
        lgu: '',
        status: ''
    },
    modal: {
        isOpen: false,
        mode: 'create', // 'create' or 'edit'
        destination: null
    },
    deleteModal: {
        isOpen: false,
        destination: null
    }
};

async function init() {
    if (state.token && state.user && state.user.role === 'admin') {
        await loadMetaData();
        await loadDestinations();
    }
    render();
}

async function apiRequest(endpoint, options = {}) {
    const headers = {
        'Content-Type': 'application/json',
        ...(state.token ? { 'Authorization': `Bearer ${state.token}` } : {})
    };

    try {
        const res = await fetch(`${API_BASE_URL}${endpoint}`, {
            ...options,
            headers: { ...headers, ...(options.headers || {}) }
        });
        
        const data = await res.json();
        if (!res.ok) {
            throw new Error(data.message || data.error || `HTTP error ${res.status}`);
        }
        return data;
    } catch (err) {
        throw err;
    }
}

async function loadMetaData() {
    try {
        const [lgusRes, taxonomyRes] = await Promise.all([
            apiRequest('/destinations/lgus'),
            apiRequest('/destinations/taxonomy')
        ]);
        state.lgus = lgusRes.data || lgusRes;
        state.taxonomy = taxonomyRes.data || taxonomyRes;
    } catch (err) {
        console.error('Failed to load metadata:', err);
    }
}

async function loadDestinations() {
    state.loading = true;
    render();
    try {
        const res = await apiRequest('/destinations?limit=200');
        state.destinations = res.data || res.items || [];
        state.error = null;
    } catch (err) {
        state.error = err.message;
    } finally {
        state.loading = false;
        render();
    }
}

async function handleLogin(e) {
    e.preventDefault();
    const email = document.getElementById('login-email').value;
    const password = document.getElementById('login-password').value;
    
    state.loading = true;
    state.error = null;
    render();

    try {
        const res = await apiRequest('/auth/login', {
            method: 'POST',
            body: JSON.stringify({ email, password })
        });

        const user = res.data?.user || res.user;
        const token = res.data?.token || res.token;

        if (user.role !== 'admin') {
            throw new Error('Access denied: Administrator privileges required. Tourist accounts cannot access the Web Admin Portal.');
        }

        state.token = token;
        state.user = user;
        localStorage.setItem('nb_admin_token', token);
        localStorage.setItem('nb_admin_user', JSON.stringify(user));

        await loadMetaData();
        await loadDestinations();
    } catch (err) {
        state.error = err.message;
    } finally {
        state.loading = false;
        render();
    }
}

function handleLogout() {
    state.token = null;
    state.user = null;
    state.destinations = [];
    localStorage.removeItem('nb_admin_token');
    localStorage.removeItem('nb_admin_user');
    render();
}

async function toggleStatus(id, currentStatus) {
    const newStatus = currentStatus === 'verified' ? 'needs_field_verification' : 'verified';
    try {
        await apiRequest(`/admin/destinations/${id}/status`, {
            method: 'PATCH',
            body: JSON.stringify({ verificationStatus: newStatus })
        });
        state.success = `Updated verification status successfully.`;
        setTimeout(() => { state.success = null; render(); }, 3000);
        await loadDestinations();
    } catch (err) {
        state.error = err.message;
        render();
    }
}

async function handleSaveDestination(e) {
    e.preventDefault();
    const form = e.target;
    const formData = new FormData(form);
    
    const payload = {
        name: formData.get('name'),
        slug: formData.get('slug'),
        lguCode: formData.get('lguCode'),
        tourismCluster: formData.get('tourismCluster'),
        categoryCode: formData.get('categoryCode'),
        description: formData.get('description'),
        address: formData.get('address'),
        latitude: parseFloat(formData.get('latitude')),
        longitude: parseFloat(formData.get('longitude')),
        entityType: formData.get('entityType'),
        popularityTier: formData.get('popularityTier'),
        highwayAccessible: formData.get('highwayAccessible') === 'on',
        verificationStatus: formData.get('verificationStatus'),
        pricing: {
            isFree: formData.get('isFree') === 'on',
            entranceFeeAdult: parseFloat(formData.get('entranceFeeAdult') || 0),
            estimatedMealMin: parseFloat(formData.get('estimatedMealMin') || 0),
            estimatedMealMax: parseFloat(formData.get('estimatedMealMax') || 0)
        }
    };

    const isEdit = state.modal.mode === 'edit';
    const destId = state.modal.destination?.id;

    try {
        if (isEdit) {
            await apiRequest(`/admin/destinations/${destId}`, {
                method: 'PUT',
                body: JSON.stringify(payload)
            });
            state.success = 'Destination updated successfully.';
        } else {
            await apiRequest('/admin/destinations', {
                method: 'POST',
                body: JSON.stringify(payload)
            });
            state.success = 'Destination created successfully.';
        }
        
        closeModal();
        setTimeout(() => { state.success = null; render(); }, 3000);
        await loadDestinations();
    } catch (err) {
        state.error = err.message;
        render();
    }
}

async function handleDeleteDestination(id) {
    try {
        await apiRequest(`/admin/destinations/${id}`, {
            method: 'DELETE'
        });
        state.success = 'Destination deleted successfully.';
        closeDeleteModal();
        setTimeout(() => { state.success = null; render(); }, 3000);
        await loadDestinations();
    } catch (err) {
        state.error = err.message;
        render();
    }
}

function openModal(mode, destination = null) {
    state.modal = { isOpen: true, mode, destination };
    render();
}

function closeModal() {
    state.modal = { isOpen: false, mode: 'create', destination: null };
    render();
}

function openDeleteModal(destination) {
    state.deleteModal = { isOpen: true, destination };
    render();
}

function closeDeleteModal() {
    state.deleteModal = { isOpen: false, destination: null };
    render();
}

function render() {
    const app = document.getElementById('app');
    
    if (!state.token || !state.user || state.user.role !== 'admin') {
        app.innerHTML = renderLoginView();
        return;
    }

    app.innerHTML = renderDashboardView();
}

function renderLoginView() {
    return `
        <div class="flex-1 flex items-center justify-center p-6">
            <div class="w-full max-w-md bg-[#FAF4EC] squircle p-8 shadow-xl border border-[#092008]/10">
                <div class="text-center mb-8">
                    <div class="inline-flex items-center justify-center w-16 h-16 squircle bg-[#092008] text-[#FAF4EC] mb-4">
                        <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"/></svg>
                    </div>
                    <h1 class="text-2xl font-bold text-[#092008]">NORTE BOUND</h1>
                    <p class="text-sm text-[#092008]/70 mt-1">Curator Admin Portal — Ilocos Norte Tourism</p>
                </div>

                ${state.error ? `
                    <div class="mb-6 p-4 squircle-sm bg-red-100 text-red-800 text-sm border border-red-200">
                        ${state.error}
                    </div>
                ` : ''}

                <form onsubmit="handleLogin(event)" class="space-y-5">
                    <div>
                        <label class="block text-xs font-bold uppercase tracking-wider text-[#092008]/80 mb-2">Admin Email</label>
                        <input type="email" id="login-email" required value="admin@nortebound.ph" 
                            class="w-full px-4 py-3 squircle-sm bg-white border border-[#092008]/20 focus:outline-none focus:border-[#092008] text-sm">
                    </div>
                    <div>
                        <label class="block text-xs font-bold uppercase tracking-wider text-[#092008]/80 mb-2">Password</label>
                        <input type="password" id="login-password" required value="AdminPass123!" 
                            class="w-full px-4 py-3 squircle-sm bg-white border border-[#092008]/20 focus:outline-none focus:border-[#092008] text-sm">
                    </div>
                    <button type="submit" ${state.loading ? 'disabled' : ''} 
                        class="w-full py-3.5 squircle-sm bg-[#E27D5A] text-[#FAF4EC] font-semibold hover:opacity-95 transition shadow-md flex items-center justify-center space-x-2">
                        <span>${state.loading ? 'Authenticating...' : 'Sign In as Curator'}</span>
                    </button>
                </form>
            </div>
        </div>
    `;
}

function renderDashboardView() {
    const filteredDestinations = state.destinations.filter(d => {
        const matchesSearch = !state.filter.search || d.name.toLowerCase().includes(state.filter.search.toLowerCase()) || d.lguName.toLowerCase().includes(state.filter.search.toLowerCase());
        const matchesLgu = !state.filter.lgu || d.lguCode === state.filter.lgu;
        const matchesStatus = !state.filter.status || d.verificationStatus === state.filter.status;
        return matchesSearch && matchesLgu && matchesStatus;
    });

    const totalCount = state.destinations.length;
    const verifiedCount = state.destinations.filter(d => d.verificationStatus === 'verified').length;
    const hiddenGemsCount = state.destinations.filter(d => d.popularityTier === 'hidden_gem').length;

    return `
        <!-- Top Nav -->
        <header class="bg-[#092008] text-[#FAF4EC] px-6 py-4 flex items-center justify-between shadow-md">
            <div class="flex items-center space-x-3">
                <div class="w-10 h-10 squircle-sm bg-[#E27D5A] flex items-center justify-center font-bold text-lg">NB</div>
                <div>
                    <h1 class="font-bold text-lg leading-tight">NORTE BOUND</h1>
                    <p class="text-xs text-[#FAF4EC]/70">Curator Admin Portal</p>
                </div>
            </div>
            <div class="flex items-center space-x-4">
                <span class="px-3 py-1 squircle-sm bg-[#87CEEB]/20 text-[#87CEEB] text-xs font-semibold">ADMIN: ${state.user.email}</span>
                <button onclick="handleLogout()" class="px-4 py-2 squircle-sm bg-white/10 hover:bg-white/20 text-xs font-semibold transition">Sign Out</button>
            </div>
        </header>

        <!-- Main Content -->
        <main class="flex-1 max-w-7xl w-full mx-auto px-6 py-8 flex flex-col space-y-6">
            
            ${state.success ? `
                <div class="p-4 squircle bg-green-100 text-green-800 text-sm border border-green-200 shadow-sm flex items-center justify-between">
                    <span>${state.success}</span>
                </div>
            ` : ''}

            ${state.error ? `
                <div class="p-4 squircle bg-red-100 text-red-800 text-sm border border-red-200 shadow-sm flex items-center justify-between">
                    <span>${state.error}</span>
                    <button onclick="state.error = null; render();" class="text-xs font-bold underline">Dismiss</button>
                </div>
            ` : ''}

            <!-- Stats Bar -->
            <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div class="bg-[#FAF4EC] squircle p-6 border border-[#092008]/10 shadow-sm">
                    <p class="text-xs font-bold uppercase tracking-wider text-[#092008]/60">Total Destinations</p>
                    <p class="text-3xl font-extrabold text-[#092008] mt-2">${totalCount}</p>
                </div>
                <div class="bg-[#FAF4EC] squircle p-6 border border-[#092008]/10 shadow-sm">
                    <p class="text-xs font-bold uppercase tracking-wider text-[#092008]/60">Verified Records</p>
                    <p class="text-3xl font-extrabold text-green-700 mt-2">${verifiedCount}</p>
                </div>
                <div class="bg-[#FAF4EC] squircle p-6 border border-[#092008]/10 shadow-sm">
                    <p class="text-xs font-bold uppercase tracking-wider text-[#092008]/60">Hidden Gems</p>
                    <p class="text-3xl font-extrabold text-[#E27D5A] mt-2">${hiddenGemsCount}</p>
                </div>
            </div>

            <!-- Controls & Filters Bar -->
            <div class="bg-[#FAF4EC] squircle p-6 border border-[#092008]/10 shadow-sm flex flex-col md:flex-row items-center justify-between gap-4">
                <div class="flex flex-wrap items-center gap-3 w-full md:w-auto flex-1">
                    <input type="text" placeholder="Search destinations or LGUs..." 
                        value="${state.filter.search}" oninput="state.filter.search = this.value; render();"
                        class="px-4 py-2.5 squircle-sm bg-white border border-[#092008]/20 text-sm w-full md:w-72 focus:outline-none focus:border-[#092008]">
                    
                    <select onchange="state.filter.lgu = this.value; render();" 
                        class="px-4 py-2.5 squircle-sm bg-white border border-[#092008]/20 text-sm focus:outline-none focus:border-[#092008]">
                        <option value="">All 23 LGUs</option>
                        ${state.lgus.map(l => `<option value="${l.lguCode}" ${state.filter.lgu === l.lguCode ? 'selected' : ''}>${l.name} (${l.lguType})</option>`).join('')}
                    </select>

                    <select onchange="state.filter.status = this.value; render();" 
                        class="px-4 py-2.5 squircle-sm bg-white border border-[#092008]/20 text-sm focus:outline-none focus:border-[#092008]">
                        <option value="">All Verification Status</option>
                        <option value="verified" ${state.filter.status === 'verified' ? 'selected' : ''}>Verified</option>
                        <option value="needs_field_verification" ${state.filter.status === 'needs_field_verification' ? 'selected' : ''}>Needs Field Verification</option>
                    </select>
                </div>

                <button onclick="openModal('create')" 
                    class="px-5 py-2.5 squircle-sm bg-[#E27D5A] text-[#FAF4EC] font-semibold text-sm hover:opacity-95 transition shadow-sm flex items-center space-x-2 whitespace-nowrap">
                    <span>+ Add Destination</span>
                </button>
            </div>

            <!-- Destinations Table -->
            <div class="bg-[#FAF4EC] squircle border border-[#092008]/10 shadow-sm overflow-hidden flex-1">
                <div class="overflow-x-auto">
                    <table class="w-full text-left border-collapse">
                        <thead>
                            <tr class="bg-[#092008]/5 border-b border-[#092008]/10 text-xs font-bold uppercase tracking-wider text-[#092008]/70">
                                <th class="p-4">Destination Name</th>
                                <th class="p-4">LGU</th>
                                <th class="p-4">Category</th>
                                <th class="p-4">Popularity Tier</th>
                                <th class="p-4">Verification Status</th>
                                <th class="p-4 text-right">Actions</th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-[#092008]/10 text-sm">
                            ${state.loading ? `
                                <tr><td colspan="6" class="p-8 text-center text-[#092008]/60">Loading destinations...</td></tr>
                            ` : filteredDestinations.length === 0 ? `
                                <tr><td colspan="6" class="p-8 text-center text-[#092008]/60">No destinations found matching filter criteria.</td></tr>
                            ` : filteredDestinations.map(d => `
                                <tr class="hover:bg-[#092008]/5 transition">
                                    <td class="p-4 font-semibold text-[#092008]">
                                        ${d.name}
                                        <div class="text-xs font-normal text-[#092008]/60">${d.slug}</div>
                                    </td>
                                    <td class="p-4">${d.lguName || d.lguCode}</td>
                                    <td class="p-4">
                                        <span class="px-2.5 py-1 squircle-sm bg-[#092008]/10 text-xs font-medium">${d.categoryName || d.categoryCode}</span>
                                    </td>
                                    <td class="p-4">
                                        <span class="px-2.5 py-1 squircle-sm text-xs font-semibold ${d.popularityTier === 'hidden_gem' ? 'bg-[#E27D5A]/20 text-[#E27D5A]' : 'bg-[#092008]/10 text-[#092008]'}">
                                            ${d.popularityTier.replace('_', ' ').toUpperCase()}
                                        </span>
                                    </td>
                                    <td class="p-4">
                                        <button onclick="toggleStatus(${d.id}, '${d.verificationStatus}')" 
                                            class="px-3 py-1 squircle-sm text-xs font-bold transition ${d.verificationStatus === 'verified' ? 'bg-green-100 text-green-800 hover:bg-green-200' : 'bg-amber-100 text-amber-800 hover:bg-amber-200'}">
                                            ${d.verificationStatus === 'verified' ? '✓ Verified' : '⚠ Needs Verification'}
                                        </button>
                                    </td>
                                    <td class="p-4 text-right space-x-2">
                                        <button onclick="openModal('edit', ${JSON.stringify(d).replace(/"/g, '&quot;')})" 
                                            class="px-3 py-1.5 squircle-sm bg-[#092008]/10 hover:bg-[#092008]/20 font-semibold text-xs transition">Edit</button>
                                        <button onclick="openDeleteModal(${JSON.stringify(d).replace(/"/g, '&quot;')})" 
                                            class="px-3 py-1.5 squircle-sm bg-red-100 hover:bg-red-200 text-red-800 font-semibold text-xs transition">Delete</button>
                                    </td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                </div>
            </div>
        </main>

        <!-- Add / Edit Modal -->
        ${state.modal.isOpen ? renderDestinationModal() : ''}

        <!-- Delete Guard Modal -->
        ${state.deleteModal.isOpen ? renderDeleteModal() : ''}
    `;
}

function renderDestinationModal() {
    const isEdit = state.modal.mode === 'edit';
    const d = state.modal.destination || {};
    const pricing = d.pricing || {};

    return `
        <div class="fixed inset-0 bg-[#092008]/50 backdrop-blur-sm flex items-center justify-center p-4 z-50 overflow-y-auto">
            <div class="bg-[#FAF4EC] squircle w-full max-w-2xl p-8 shadow-2xl border border-[#092008]/20 my-8">
                <div class="flex items-center justify-between mb-6">
                    <h2 class="text-xl font-bold text-[#092008]">${isEdit ? 'Edit Destination' : 'Add New Destination'}</h2>
                    <button onclick="closeModal()" class="text-[#092008]/60 hover:text-[#092008] font-bold text-lg">✕</button>
                </div>

                <form onsubmit="handleSaveDestination(event)" class="space-y-4">
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                            <label class="block text-xs font-bold uppercase tracking-wider text-[#092008]/80 mb-1">Destination Name</label>
                            <input type="text" name="name" required value="${d.name || ''}" 
                                class="w-full px-3 py-2 squircle-sm bg-white border border-[#092008]/20 text-sm focus:outline-none">
                        </div>
                        <div>
                            <label class="block text-xs font-bold uppercase tracking-wider text-[#092008]/80 mb-1">URL Slug</label>
                            <input type="text" name="slug" required value="${d.slug || ''}" 
                                class="w-full px-3 py-2 squircle-sm bg-white border border-[#092008]/20 text-sm focus:outline-none" placeholder="e.g. saud-beach">
                        </div>
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                        <div>
                            <label class="block text-xs font-bold uppercase tracking-wider text-[#092008]/80 mb-1">LGU</label>
                            <select name="lguCode" required class="w-full px-3 py-2 squircle-sm bg-white border border-[#092008]/20 text-sm focus:outline-none">
                                ${state.lgus.map(l => `<option value="${l.lguCode}" ${d.lguCode === l.lguCode ? 'selected' : ''}>${l.name}</option>`).join('')}
                            </select>
                        </div>
                        <div>
                            <label class="block text-xs font-bold uppercase tracking-wider text-[#092008]/80 mb-1">Tourism Cluster</label>
                            <select name="tourismCluster" required class="w-full px-3 py-2 squircle-sm bg-white border border-[#092008]/20 text-sm focus:outline-none">
                                <option value="northern_coast" ${d.tourismCluster === 'northern_coast' ? 'selected' : ''}>Northern Coast</option>
                                <option value="central_urban_heritage" ${d.tourismCluster === 'central_urban_heritage' ? 'selected' : ''}>Central Heritage</option>
                                <option value="southern_heritage_coast" ${d.tourismCluster === 'southern_heritage_coast' ? 'selected' : ''}>Southern Coast</option>
                                <option value="eastern_agri_highland" ${d.tourismCluster === 'eastern_agri_highland' ? 'selected' : ''}>Eastern Highland</option>
                            </select>
                        </div>
                        <div>
                            <label class="block text-xs font-bold uppercase tracking-wider text-[#092008]/80 mb-1">Category Code</label>
                            <select name="categoryCode" required class="w-full px-3 py-2 squircle-sm bg-white border border-[#092008]/20 text-sm focus:outline-none">
                                ${state.taxonomy.map(t => `<option value="${t.categoryCode}" ${d.categoryCode === t.categoryCode ? 'selected' : ''}>${t.name}</option>`).join('')}
                            </select>
                        </div>
                    </div>

                    <div>
                        <label class="block text-xs font-bold uppercase tracking-wider text-[#092008]/80 mb-1">Description</label>
                        <textarea name="description" rows="3" required class="w-full px-3 py-2 squircle-sm bg-white border border-[#092008]/20 text-sm focus:outline-none">${d.description || ''}</textarea>
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                        <div>
                            <label class="block text-xs font-bold uppercase tracking-wider text-[#092008]/80 mb-1">Address</label>
                            <input type="text" name="address" required value="${d.address || ''}" 
                                class="w-full px-3 py-2 squircle-sm bg-white border border-[#092008]/20 text-sm focus:outline-none">
                        </div>
                        <div>
                            <label class="block text-xs font-bold uppercase tracking-wider text-[#092008]/80 mb-1">Latitude</label>
                            <input type="number" step="any" name="latitude" required value="${d.latitude || 18.5}" 
                                class="w-full px-3 py-2 squircle-sm bg-white border border-[#092008]/20 text-sm focus:outline-none">
                        </div>
                        <div>
                            <label class="block text-xs font-bold uppercase tracking-wider text-[#092008]/80 mb-1">Longitude</label>
                            <input type="number" step="any" name="longitude" required value="${d.longitude || 120.8}" 
                                class="w-full px-3 py-2 squircle-sm bg-white border border-[#092008]/20 text-sm focus:outline-none">
                        </div>
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                        <div>
                            <label class="block text-xs font-bold uppercase tracking-wider text-[#092008]/80 mb-1">Popularity Tier</label>
                            <select name="popularityTier" required class="w-full px-3 py-2 squircle-sm bg-white border border-[#092008]/20 text-sm focus:outline-none">
                                <option value="iconic_hub" ${d.popularityTier === 'iconic_hub' ? 'selected' : ''}>Iconic Hub</option>
                                <option value="moderate" ${d.popularityTier === 'moderate' ? 'selected' : ''}>Moderate</option>
                                <option value="hidden_gem" ${d.popularityTier === 'hidden_gem' ? 'selected' : ''}>Hidden Gem</option>
                            </select>
                        </div>
                        <div>
                            <label class="block text-xs font-bold uppercase tracking-wider text-[#092008]/80 mb-1">Entity Type</label>
                            <select name="entityType" required class="w-full px-3 py-2 squircle-sm bg-white border border-[#092008]/20 text-sm focus:outline-none">
                                <option value="attraction" ${d.entityType === 'attraction' ? 'selected' : ''}>Attraction</option>
                                <option value="restaurant" ${d.entityType === 'restaurant' ? 'selected' : ''}>Restaurant</option>
                                <option value="hotel" ${d.entityType === 'hotel' ? 'selected' : ''}>Hotel</option>
                            </select>
                        </div>
                        <div>
                            <label class="block text-xs font-bold uppercase tracking-wider text-[#092008]/80 mb-1">Verification Status</label>
                            <select name="verificationStatus" required class="w-full px-3 py-2 squircle-sm bg-white border border-[#092008]/20 text-sm focus:outline-none">
                                <option value="verified" ${d.verificationStatus === 'verified' ? 'selected' : ''}>Verified</option>
                                <option value="needs_field_verification" ${d.verificationStatus === 'needs_field_verification' ? 'selected' : ''}>Needs Field Verification</option>
                            </select>
                        </div>
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-4 gap-4 p-4 squircle-sm bg-[#092008]/5 border border-[#092008]/10">
                        <div class="md:col-span-4 flex items-center space-x-3">
                            <input type="checkbox" name="isFree" id="isFree" ${pricing.isFree ? 'checked' : ''} class="w-4 h-4">
                            <label for="isFree" class="text-xs font-bold uppercase tracking-wider text-[#092008]">Free Entry / Admission</label>
                        </div>
                        <div>
                            <label class="block text-xs font-bold uppercase tracking-wider text-[#092008]/80 mb-1">Adult Entrance Fee (₱)</label>
                            <input type="number" step="0.01" name="entranceFeeAdult" value="${pricing.entranceFeeAdult || 0}" class="w-full px-3 py-2 squircle-sm bg-white border border-[#092008]/20 text-sm focus:outline-none">
                        </div>
                        <div>
                            <label class="block text-xs font-bold uppercase tracking-wider text-[#092008]/80 mb-1">Min Meal Cost (₱)</label>
                            <input type="number" step="0.01" name="estimatedMealMin" value="${pricing.estimatedMealMin || 0}" class="w-full px-3 py-2 squircle-sm bg-white border border-[#092008]/20 text-sm focus:outline-none">
                        </div>
                        <div>
                            <label class="block text-xs font-bold uppercase tracking-wider text-[#092008]/80 mb-1">Max Meal Cost (₱)</label>
                            <input type="number" step="0.01" name="estimatedMealMax" value="${pricing.estimatedMealMax || 0}" class="w-full px-3 py-2 squircle-sm bg-white border border-[#092008]/20 text-sm focus:outline-none">
                        </div>
                        <div class="flex items-center">
                            <input type="checkbox" name="highwayAccessible" id="highwayAccessible" ${d.highwayAccessible !== false ? 'checked' : ''} class="w-4 h-4">
                            <label for="highwayAccessible" class="ml-2 text-xs font-bold uppercase tracking-wider text-[#092008]">Highway Accessible</label>
                        </div>
                    </div>

                    <div class="flex items-center justify-end space-x-3 pt-4">
                        <button type="button" onclick="closeModal()" class="px-5 py-2.5 squircle-sm bg-[#092008]/10 hover:bg-[#092008]/20 font-semibold text-sm transition">Cancel</button>
                        <button type="submit" class="px-5 py-2.5 squircle-sm bg-[#E27D5A] text-[#FAF4EC] font-semibold text-sm hover:opacity-95 transition shadow-sm">${isEdit ? 'Save Changes' : 'Create Destination'}</button>
                    </div>
                </form>
            </div>
        </div>
    `;
}

function renderDeleteModal() {
    const d = state.deleteModal.destination;
    return `
        <div class="fixed inset-0 bg-[#092008]/50 backdrop-blur-sm flex items-center justify-center p-4 z-50">
            <div class="bg-[#FAF4EC] squircle w-full max-w-md p-6 shadow-2xl border border-[#092008]/20">
                <h3 class="text-lg font-bold text-[#092008] mb-2">Delete Destination</h3>
                <p class="text-sm text-[#092008]/80 mb-6">Are you sure you want to delete <strong class="text-[#092008]">${d.name}</strong>? This action cannot be undone and removes the record from active itineraries and recommendation indices.</p>
                
                <div class="flex items-center justify-end space-x-3">
                    <button onclick="closeDeleteModal()" class="px-4 py-2 squircle-sm bg-[#092008]/10 hover:bg-[#092008]/20 font-semibold text-sm transition">Cancel</button>
                    <button onclick="handleDeleteDestination(${d.id})" class="px-4 py-2 squircle-sm bg-red-600 text-white font-semibold text-sm hover:bg-red-700 transition shadow-sm">Delete Record</button>
                </div>
            </div>
        </div>
    `;
}

// Initialize on DOM ready
document.addEventListener('DOMContentLoaded', init);
