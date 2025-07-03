// This script assumes firebase-config.js is loaded first and initializes `window.firebase`

// Import Firebase services
import { initializeApp } from "https://www.gstatic.com/firebasejs/9.17.1/firebase-app-compat.js";
import { getAuth, onAuthStateChanged, signOut } from "https://www.gstatic.com/firebasejs/9.17.1/firebase-auth-compat.js";
import { getFirestore, collection, getDocs, doc, getDoc, query, orderBy } from "https://www.gstatic.com/firebasejs/9.17.1/firebase-firestore-compat.js";
import { getFunctions, httpsCallable } from "https://www.gstatic.com/firebasejs/9.17.1/firebase-functions-compat.js";

// Initialize Firebase services from the global window object
const firebaseApp = window.firebase.app();
const auth = getAuth(firebaseApp);
const db = getFirestore(firebaseApp);
const functions = getFunctions(firebaseApp);

// --- AUTH GUARD & INITIALIZATION ---
onAuthStateChanged(auth, user => {
    if (user) {
        // Check if the user is an admin
        user.getIdTokenResult(true).then(idTokenResult => {
            if (idTokenResult.claims.admin) {
                document.body.style.visibility = 'visible';
                initializeDashboard();
            } else {
                // If not an admin, sign out and redirect to login
                signOut(auth).then(() => window.location.href = '/login.html');
            }
        });
    } else {
        // No user logged in, redirect
        window.location.href = '/login.html';
    }
});

function initializeDashboard() {
    setupNavigation();
    loadDashboardData();
    loadUsers();

    document.getElementById('logout-btn').addEventListener('click', () => signOut(auth));

    const adminForm = document.getElementById('admin-signup-form');
    adminForm.addEventListener('submit', handleAdminFormSubmit);
}

// --- NAVIGATION ---
function setupNavigation() {
    const navItems = document.querySelectorAll('.nav-item');
    const sections = document.querySelectorAll('.content-section');

    const switchView = (targetId) => {
        sections.forEach(s => s.classList.toggle('active', s.id === targetId));
        navItems.forEach(n => n.classList.toggle('active', n.dataset.section === targetId));
    };

    navItems.forEach(item => {
        item.addEventListener('click', (e) => {
            e.preventDefault();
            switchView(item.dataset.section);
        });
    });

    document.getElementById('back-to-users-btn').addEventListener('click', () => switchView('user-management-section'));

    document.getElementById('user-table-body').addEventListener('click', handleUserActions);
    
    document.querySelectorAll('.user-detail-tabs .tab').forEach(tab => {
        tab.addEventListener('click', () => handleTabSwitching(tab));
    });
}

// --- EVENT HANDLERS ---
async function handleUserActions(e) {
    const button = e.target.closest('button');
    if (!button) return;

    const userId = button.dataset.userId;
    const action = button.dataset.action;

    if (action === 'view') {
        loadUserDetail(userId);
        document.querySelector('.nav-item[data-section="user-management-section"]').classList.remove('active');
        document.querySelectorAll('.content-section').forEach(s => s.classList.remove('active'));
        document.getElementById('user-detail-section').classList.add('active');
    } else if (action === 'suspend') {
        const currentStatus = button.dataset.status === 'true';
        toggleUserStatus(userId, !currentStatus);
    } else if (action === 'delete') {
        if (confirm(`Are you sure you want to permanently delete user ${userId}? This cannot be undone.`)) {
            deleteUser(userId);
        }
    }
}

function handleTabSwitching(clickedTab) {
    document.querySelectorAll('.user-detail-tabs .tab').forEach(t => t.classList.remove('active'));
    clickedTab.classList.add('active');
    const targetContentId = `tab-${clickedTab.dataset.tab}`;
    document.querySelectorAll('.tab-content').forEach(c => c.classList.toggle('active', c.id === targetContentId));
}

async function handleAdminFormSubmit(e) {
    e.preventDefault();
    const email = e.target.email.value;
    const submitBtn = e.target.querySelector('button[type="submit"]');
    const statusEl = document.getElementById('signup-status-message');

    if (!email) {
        showStatus('Please enter a valid email address.', 'error', statusEl);
        return;
    }

    submitBtn.disabled = true;
    submitBtn.textContent = 'Processing...';

    const setUserAsAdmin = httpsCallable(functions, 'setUserAsAdmin');
    try {
        const result = await setUserAsAdmin({ email });
        showStatus(result.data.message, 'success', statusEl);
        e.target.reset();
    } catch (error) {
        showStatus(error.message, 'error', statusEl);
    } finally {
        submitBtn.disabled = false;
        submitBtn.textContent = 'Process Request';
    }
}

// --- DATA FETCHING & RENDERING ---
async function loadDashboardData() {
    const getAnalyticsData = httpsCallable(functions, 'getAnalyticsData');
    try {
        const result = await getAnalyticsData();
        const data = result.data;
        document.getElementById('total-users').textContent = data.totalUsers ?? '0';
        document.getElementById('active-users').textContent = data.newSignups ?? '0';
        renderCharts(data);
    } catch (error) {
        console.error("Error fetching analytics data:", error);
    }
}

async function loadUsers() {
    const tbody = document.getElementById('user-table-body');
    tbody.innerHTML = '<tr><td colspan="5" style="text-align:center;">Loading users...</td></tr>';
    try {
        const usersSnapshot = await getDocs(query(collection(db, 'users'), orderBy('email')));
        if (usersSnapshot.empty) {
            tbody.innerHTML = '<tr><td colspan="5" style="text-align:center;">No users found.</td></tr>';
            return;
        }
        tbody.innerHTML = '';
        usersSnapshot.forEach(doc => {
            const user = { id: doc.id, ...doc.data() };
            const status = user.disabled ? 'Suspended' : 'Active';
            const row = `
                <tr>
                    <td>
                        <div class="user-profile">
                            <div class="user-avatar">${(user.displayName || user.email).charAt(0).toUpperCase()}</div>
                            <div class="user-info">
                                <div class="name">${user.displayName || 'N/A'}</div>
                                <div class="email">${user.email}</div>
                            </div>
                        </div>
                    </td>
                    <td>${user.createdAt ? new Date(user.createdAt.seconds * 1000).toLocaleDateString() : 'N/A'}</td>
                    <td>${user.lastActive ? new Date(user.lastActive.seconds * 1000).toLocaleDateString() : 'N/A'}</td>
                    <td><span class="${status === 'Active' ? 'text-success' : 'text-danger'}">${status}</span></td>
                    <td class="table-actions">
                        <button class="btn btn-secondary" data-user-id="${user.id}" data-action="view">View</button>
                        <button class="btn btn-danger" data-user-id="${user.id}" data-action="suspend" data-status="${user.disabled || false}">${status === 'Active' ? 'Suspend' : 'Enable'}</button>
                    </td>
                </tr>
            `;
            tbody.innerHTML += row;
        });
    } catch (error) {
        tbody.innerHTML = '<tr><td colspan="5" style="text-align:center;color:red;">Failed to load users.</td></tr>';
        console.error("Error fetching users:", error);
    }
}

async function loadUserDetail(userId) {
    const userDoc = await getDoc(doc(db, 'users', userId));
    if (userDoc.exists()) {
        const user = userDoc.data();
        document.getElementById('user-detail-avatar').textContent = (user.displayName || user.email).charAt(0).toUpperCase();
        document.getElementById('user-detail-name').textContent = user.displayName || 'N/A';
        document.getElementById('user-detail-email').textContent = user.email;
        // Further implementation can fetch transactions, goals, etc.
    }
}

// --- USER ACTIONS (CALLING CLOUD FUNCTIONS) ---
async function toggleUserStatus(uid, shouldDisable) {
    const toggleUser = httpsCallable(functions, 'toggleUserStatus');
    try {
        await toggleUser({ uid, disable: shouldDisable });
        showActionStatus(`User status updated successfully.`, 'success');
        loadUsers(); // Refresh list
    } catch (error) {
        showActionStatus(error.message, 'error');
    }
}

async function deleteUser(uid) {
    const deleteUserData = httpsCallable(functions, 'deleteUserData');
    try {
        await deleteUserData({ uid });
        showActionStatus(`User deleted successfully.`, 'success');
        loadUsers(); // Refresh list
    } catch (error) {
        showActionStatus(error.message, 'error');
    }
}

// --- UI UTILITY FUNCTIONS ---
function showStatus(message, type, element) {
    element.textContent = message;
    element.className = `status-message status-${type}`;
    element.style.display = 'block';
    setTimeout(() => { element.style.display = 'none'; }, 6000);
}

function showActionStatus(message, type = 'success') {
    const el = document.getElementById('action-status-message');
    if (el) showStatus(message, type, el);
}

function renderCharts(data) {
    // Destroy old charts if they exist
    if (window.registrationsChart) window.registrationsChart.destroy();
    if (window.activityChart) window.activityChart.destroy();

    // User Registrations Chart
    const regCtx = document.getElementById('user-registrations-chart').getContext('2d');
    window.registrationsChart = new Chart(regCtx, {
        type: 'bar',
        data: {
            labels: ['Week 1', 'Week 2', 'Week 3', 'Week 4'], // Placeholder data
            datasets: [{
                label: 'New Users',
                data: [65, 59, 80, 81], // Placeholder data
                backgroundColor: 'rgba(94, 53, 177, 0.2)',
                borderColor: 'rgba(94, 53, 177, 1)',
                borderWidth: 1
            }]
        }
    });

    // User Activity Chart (Leaderboard)
    const activityCtx = document.getElementById('user-activity-chart').getContext('2d');
    const leaderboard = data.leaderboard || [];
    window.activityChart = new Chart(activityCtx, {
        type: 'pie',
        data: {
            labels: leaderboard.length ? leaderboard.map(u => u.name) : ['No Data'],
            datasets: [{
                data: leaderboard.length ? leaderboard.map(u => u.goalsCompleted) : [1],
                backgroundColor: ['#5E35B1', '#7E57C2', '#9575CD', '#B39DDB', '#D1C4E9'],
            }]
        },
        options: { plugins: { legend: { position: 'top' } } }
    });
}