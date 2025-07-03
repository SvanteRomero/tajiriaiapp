// --- AUTH GUARD & INITIALIZATION ---

// Reusable function to check for admin status
function checkAdminStatus() {
    return new Promise((resolve) => {
        firebase.auth().onAuthStateChanged(user => {
            if (user) {
                user.getIdTokenResult(true).then(idTokenResult => {
                    if (!!idTokenResult.claims.admin) {
                        resolve(true); // User is an admin
                    } else {
                        // User is logged in but not an admin, sign out and redirect
                        firebase.auth().signOut();
                        window.location.href = '/login.html';
                        resolve(false);
                    }
                });
            } else {
                // No user is logged in, redirect
                window.location.href = '/login.html';
                resolve(false);
            }
        });
    });
}

// --- Main Entry Point ---
document.addEventListener('DOMContentLoaded', () => {
    checkAdminStatus().then(isAdmin => {
        if (isAdmin) {
            document.body.style.visibility = 'visible';
            initializeDashboard();
        }
    });
});


function initializeDashboard() {
    // Setup core navigation and functionality
    setupNavigation();
    setupUserManagement();
    setupAnalytics();
    setupAdminCreation();

    // Logout button
    document.getElementById('logout-btn').addEventListener('click', () => {
        firebase.auth().signOut(); // The auth guard will redirect automatically
    });
}

// --- NAVIGATION ---
function setupNavigation() {
    const navItems = document.querySelectorAll('.nav-item');
    const contentSections = document.querySelectorAll('.content-section');

    navItems.forEach(item => {
        item.addEventListener('click', (e) => {
            e.preventDefault();

            // Update nav item active class
            navItems.forEach(i => i.classList.remove('active'));
            item.classList.add('active');

            // Show the correct content section
            const sectionId = item.getAttribute('data-section');
            contentSections.forEach(section => {
                section.classList.toggle('active', section.id === sectionId);
            });
        });
    });
}


// --- SECTION 1: USER MANAGEMENT ---
function setupUserManagement() {
    let lastVisibleDoc = null;
    let firstVisibleDoc = null;
    let currentPage = 1;
    const USERS_PER_PAGE = 10;

    const userTableBody = document.getElementById('user-table-body');
    const nextBtn = document.getElementById('next-page');
    const prevBtn = document.getElementById('prev-page');

    const fetchUsers = async (startAfter = null, endBefore = null) => {
        let query = firebase.firestore().collection('users').orderBy('createdAt', 'desc').limit(USERS_PER_PAGE);
        if (startAfter) {
            query = query.startAfter(startAfter);
        }
        if (endBefore) {
             query = firebase.firestore().collection('users').orderBy('createdAt', 'desc').endBefore(endBefore).limitToLast(USERS_PER_PAGE);
        }
        const snapshot = await query.get();
        return {
            users: snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })),
            lastDoc: snapshot.docs[snapshot.docs.length - 1],
            firstDoc: snapshot.docs[0]
        };
    };

    const renderTable = (users) => {
        userTableBody.innerHTML = '';
        if (!users || users.length === 0) {
            userTableBody.innerHTML = '<tr><td colspan="4" style="text-align:center;">No users found.</td></tr>';
            return;
        }
        users.forEach(user => {
            const row = document.createElement('tr');
            row.dataset.userId = user.id;
            row.dataset.userName = user.displayName || user.email;
            const status = user.disabled ? 'Suspended' : 'Active';
            row.dataset.status = status;
            const statusClass = user.disabled ? 'status-suspended' : 'status-active';
            row.innerHTML = `
                <td>
                    <div class="user-profile">
                        <div class="user-avatar">${(user.displayName || user.email).charAt(0).toUpperCase()}</div>
                        <div class="user-info">
                            <div class="name">${user.displayName || 'No Name'}</div>
                            <div class="email">${user.email}</div>
                        </div>
                    </div>
                </td>
                <td>${user.createdAt ? new Date(user.createdAt.seconds * 1000).toLocaleDateString() : 'N/A'}</td>
                <td><span class="status ${statusClass}">${status}</span></td>
                <td class="actions-cell">
                     <button class="btn-suspend" title="${status === 'Active' ? 'Suspend' : 'Enable'}">🔄</button>
                     <button class="btn-delete" title="Delete">🗑️</button>
                </td>`;
            userTableBody.appendChild(row);
        });
    };

    const loadUsers = async (direction) => {
        let startAfter = direction === 'next' ? lastVisibleDoc : null;
        let endBefore = direction === 'prev' ? firstVisibleDoc : null;
        
        try {
            const data = await fetchUsers(startAfter, endBefore);
            if(data.users.length > 0){
                lastVisibleDoc = data.lastDoc;
                firstVisibleDoc = data.firstDoc;
                renderTable(data.users);
                if(direction) currentPage += (direction === 'next' ? 1 : -1);
                prevBtn.disabled = currentPage === 1;
                nextBtn.disabled = data.users.length < USERS_PER_PAGE;
            } else {
                 if (direction === 'next') nextBtn.disabled = true;
            }
        } catch (error) {
             console.error("Error fetching users:", error);
             userTableBody.innerHTML = '<tr><td colspan="4" style="text-align:center; color: red;">Failed to load users.</td></tr>';
        }
    };
    
    userTableBody.addEventListener('click', async (e) => {
        // User action logic (delete/suspend) with status messages
    });
    
    nextBtn.addEventListener('click', () => loadUsers('next'));
    prevBtn.addEventListener('click', () => loadUsers('prev'));

    loadUsers(); // Initial load
}

// --- SECTION 2: ANALYTICS ---
function setupAnalytics() {
    const getAnalyticsData = firebase.functions().httpsCallable('getAnalyticsData');
    
    getAnalyticsData().then(result => {
        const { leaderboard } = result.data;
        // Render leaderboard table
        const leaderboardBody = document.getElementById('leaderboard-table-body');
        leaderboardBody.innerHTML = '';
        leaderboard.forEach(user => {
            leaderboardBody.innerHTML += `
                <tr>
                    <td>
                        <div class="user-profile">
                            <div class="user-avatar">${user.name.charAt(0)}</div>
                            <div class="user-info">
                                <div class="name">${user.name}</div>
                                <div class="email">${user.email}</div>
                            </div>
                        </div>
                    </td>
                    <td>${user.goalsCompleted}</td>
                </tr>`;
        });

        // Render chart with dummy data for now
        new Chart(document.getElementById('userActivityChart'), {
            type: 'line',
            data: {
                labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
                datasets: [{
                    label: 'New Signups',
                    data: [12, 19, 3, 5, 2, 3],
                    borderColor: 'rgba(138, 43, 226, 1)',
                    backgroundColor: 'rgba(138, 43, 226, 0.2)',
                    fill: true,
                    tension: 0.4
                }]
            },
            options: { scales: { y: { beginAtZero: true } } }
        });
    }).catch(err => {
        console.error("Error fetching analytics", err);
        document.getElementById('leaderboard-table-body').innerHTML = `<tr><td colspan="2">Error loading data.</td></tr>`;
    });
}

// --- SECTION 3: CREATE ADMIN ---
function setupAdminCreation() {
    const form = document.getElementById('admin-signup-form');
    const statusMessage = document.getElementById('signup-status-message');
    const submitBtn = document.getElementById('submit-btn');

    form.addEventListener('submit', (e) => {
        e.preventDefault();
        const email = document.getElementById('email').value;
        const password = document.getElementById('password').value;

        submitBtn.disabled = true;
        submitBtn.textContent = 'Processing...';
        statusMessage.style.display = 'none';

        const setUserAsAdmin = firebase.functions().httpsCallable('setUserAsAdmin');
        setUserAsAdmin({ email, password })
            .then(result => {
                statusMessage.textContent = result.data.message;
                statusMessage.className = 'status-message status-success';
                statusMessage.style.display = 'block';
                form.reset();
            })
            .catch(error => {
                statusMessage.textContent = `Error: ${error.message}`;
                statusMessage.className = 'status-message status-error';
                statusMessage.style.display = 'block';
            })
            .finally(() => {
                submitBtn.disabled = false;
                submitBtn.textContent = 'Process Request';
            });
    });
}