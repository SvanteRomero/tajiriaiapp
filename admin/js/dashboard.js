// This file will now access the global 'firebase' object
// No 'import' statements for Firebase needed here if loaded via CDN script tags
const auth = firebase.auth();
const db = firebase.firestore();
const functions = firebase.functions(); // If you're using Cloud Functions

// Example: Check auth state on load
auth.onAuthStateChanged(user => {
    const loadingIndicator = document.getElementById('loading-indicator');
    const wrapper = document.getElementById('wrapper');

    if (user) {
        // User is signed in. Check if they are an admin.
        // Assuming you have a Cloud Function or Firestore document to check admin status
        // For example, a callable function 'checkAdminRole'
        const checkAdmin = functions.httpsCallable('checkAdminRole');
        checkAdmin()
            .then(result => {
                if (result.data.isAdmin) {
                    loadingIndicator.style.display = 'none';
                    wrapper.style.display = 'flex'; // Show the dashboard
                    console.log("Admin logged in.");
                    // Further dashboard initialization
                    loadDashboardData();
                    setupEventListeners();
                } else {
                    console.error("User is not an admin.");
                    // Redirect to a non-admin page or show access denied message
                    window.location.href = '/not-authorized.html'; 
                }
            })
            .catch(error => {
                console.error("Error checking admin role:", error);
                // Handle error, e.g., redirect to login or show error message
                auth.signOut(); // Force sign out on error
                window.location.href = '/login.html';
            });
    } else {
        // User is signed out. Redirect to login page.
        console.log("User not signed in. Redirecting to login.");
        window.location.href = '/login.html'; // Adjust your login page path
    }
});

// ... rest of your dashboard logic (functions like loadDashboardData, setupEventListeners, etc.)

function loadDashboardData() {
    // Example: Get total users (assuming you have a Cloud Function for this or direct Firestore access)
    // For direct Firestore access to count documents:
    db.collection("users").get().then((querySnapshot) => {
        document.getElementById('total-users').textContent = querySnapshot.size;
    }).catch(error => {
        console.error("Error fetching total users:", error);
        document.getElementById('total-users').textContent = "Error";
    });

    // ... populate user table, etc.
}

function setupEventListeners() {
    // Sidebar navigation
    document.querySelectorAll('#sidebar-wrapper .list-group-item').forEach(item => {
        item.addEventListener('click', function(e) {
            e.preventDefault();
            document.querySelectorAll('.content-section').forEach(section => {
                section.style.display = 'none';
                section.classList.remove('active');
            });
            document.querySelectorAll('#sidebar-wrapper .list-group-item').forEach(navItem => {
                navItem.classList.remove('active');
            });

            const targetSectionId = this.dataset.section;
            document.getElementById(targetSectionId).style.display = 'block';
            document.getElementById(targetSectionId).classList.add('active');
            this.classList.add('active');

            // Specific actions for each section if needed
            if (targetSectionId === 'user-management-section') {
                loadUserManagementTable(); // Function to load users
            }
        });
    });

    // Menu Toggle
    document.getElementById('menu-toggle').addEventListener('click', function() {
        document.getElementById('wrapper').classList.toggle('toggled');
    });

    // Logout button
    document.getElementById('logout-btn').addEventListener('click', function() {
        auth.signOut().then(() => {
            console.log("Signed out successfully.");
            window.location.href = '/login.html'; // Redirect to login
        }).catch((error) => {
            console.error("Error signing out:", error);
            // Optionally display an error message
        });
    });

    // ... other event listeners for search, user details, create admin form, etc.
}

// Function to load users for user management table
async function loadUserManagementTable() {
    const userTableBody = document.getElementById('user-table-body');
    userTableBody.innerHTML = '<tr><td colspan="4" class="text-center">Loading users...</td></tr>';
    
    try {
        // Example: Fetch users from Firestore or a Cloud Function that lists users
        // This is simplified. In a real app, you might use a paginated list from a Cloud Function.
        const usersSnapshot = await db.collection("users").get(); // Assuming 'users' collection stores user profiles
        userTableBody.innerHTML = ''; // Clear loading message

        usersSnapshot.forEach(doc => {
            const userData = doc.data();
            const row = userTableBody.insertRow();
            row.dataset.uid = doc.id; // Store UID for detail view
            row.innerHTML = `
                <td>
                    <div class="d-flex align-items-center">
                        <div class="avatar-small me-2">${userData.displayName ? userData.displayName.charAt(0) : (userData.email ? userData.email.charAt(0) : 'U')}</div>
                        <div>
                            <div class="fw-bold">${userData.displayName || 'N/A'}</div>
                            <div class="text-muted">${userData.email || 'N/A'}</div>
                        </div>
                    </div>
                </td>
                <td>${userData.createdAt ? new Date(userData.createdAt.seconds * 1000).toLocaleDateString() : 'N/A'}</td>
                <td><span class="badge bg-success">Active</span></td> <td>
                    <button class="btn btn-sm btn-info view-user-btn" data-uid="${doc.id}">View</button>
                </td>
            `;
        });

        // Attach event listeners for view buttons
        document.querySelectorAll('.view-user-btn').forEach(button => {
            button.addEventListener('click', (e) => {
                e.preventDefault();
                showUserDetail(e.target.dataset.uid);
            });
        });

    } catch (error) {
        console.error("Error loading users:", error);
        userTableBody.innerHTML = '<tr><td colspan="4" class="text-center text-danger">Failed to load users.</td></tr>';
    }
}

async function showUserDetail(uid) {
    // Hide all sections
    document.querySelectorAll('.content-section').forEach(section => {
        section.style.display = 'none';
        section.classList.remove('active');
    });

    // Show user detail section
    const userDetailSection = document.getElementById('user-detail-section');
    userDetailSection.style.display = 'block';
    userDetailSection.classList.add('active');

    // Populate user details (fetch from Firestore or Cloud Function)
    try {
        const userDoc = await db.collection("users").doc(uid).get();
        if (userDoc.exists) {
            const userData = userDoc.data();
            document.getElementById('user-detail-name').textContent = userData.displayName || 'N/A';
            document.getElementById('user-detail-email').textContent = userData.email || 'N/A';
            document.getElementById('user-detail-uid').textContent = uid;
            document.getElementById('user-detail-created').textContent = userData.createdAt ? new Date(userData.createdAt.seconds * 1000).toLocaleDateString() : 'N/A';
            
            // Set avatar (simple initial)
            const avatarDiv = document.getElementById('user-detail-avatar');
            avatarDiv.textContent = userData.displayName ? userData.displayName.charAt(0) : (userData.email ? userData.email.charAt(0) : 'U');

            // Set status badge (example: active/suspended)
            const statusBadge = document.getElementById('user-detail-status');
            const isActive = userData.status === 'active' || userData.disabled === false; // Assuming 'disabled' field in Auth or Firestore
            statusBadge.textContent = isActive ? 'Active' : 'Suspended';
            statusBadge.className = `badge ${isActive ? 'bg-success' : 'bg-danger'}`;

            // Attach actions (suspend/delete) to buttons
            const suspendBtn = document.getElementById('suspend-user-btn');
            suspendBtn.textContent = isActive ? 'Suspend' : 'Activate';
            suspendBtn.className = `btn ${isActive ? 'btn-warning' : 'btn-success'}`;
            suspendBtn.onclick = () => toggleUserStatus(uid, isActive);

            document.getElementById('delete-user-btn').onclick = () => deleteUser(uid);

        } else {
            console.error("User document not found for UID:", uid);
            // Show error message or go back
        }
    } catch (error) {
        console.error("Error fetching user details:", error);
    }
}

document.getElementById('back-to-users-btn').addEventListener('click', () => {
    document.getElementById('user-detail-section').style.display = 'none';
    document.getElementById('user-detail-section').classList.remove('active');
    document.getElementById('user-management-section').style.display = 'block';
    document.getElementById('user-management-section').classList.add('active');
    document.querySelector('[data-section="user-management-section"]').classList.add('active');
});

// Example functions for actions (these would typically call Cloud Functions)
async function toggleUserStatus(uid, currentStatusIsActive) {
    const action = currentStatusIsActive ? 'disableUser' : 'enableUser';
    const callable = functions.httpsCallable(action);
    showStatusMessage(`Processing user status change...`, 'info');
    try {
        await callable({ uid: uid });
        showStatusMessage(`User ${currentStatusIsActive ? 'suspended' : 'activated'} successfully!`, 'success');
        // Refresh user details
        showUserDetail(uid); 
        loadUserManagementTable(); // Refresh user list
    } catch (error) {
        console.error(`Error toggling user status (${action}):`, error);
        showStatusMessage(`Failed to change user status: ${error.message}`, 'danger');
    }
}

async function deleteUser(uid) {
    if (!confirm("Are you sure you want to delete this user? This action is irreversible.")) {
        return;
    }
    const callable = functions.httpsCallable('deleteUser');
    showStatusMessage(`Deleting user...`, 'info');
    try {
        await callable({ uid: uid });
        showStatusMessage(`User deleted successfully!`, 'success');
        // Redirect back to user list or dashboard
        document.getElementById('back-to-users-btn').click(); 
        loadUserManagementTable(); // Refresh user list
    } catch (error) {
        console.error("Error deleting user:", error);
        showStatusMessage(`Failed to delete user: ${error.message}`, 'danger');
    }
}

// Admin signup form submission
document.getElementById('admin-signup-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const emailInput = document.getElementById('email');
    const passwordInput = document.getElementById('password');
    const email = emailInput.value;
    const password = passwordInput.value;
    const statusMessageDiv = document.getElementById('signup-status-message');

    statusMessageDiv.style.display = 'block';
    statusMessageDiv.className = 'alert alert-info';
    statusMessageDiv.textContent = 'Processing request...';

    try {
        // Call a Firebase Cloud Function to handle admin creation/upgrade
        const createOrUpgradeAdmin = functions.httpsCallable('createOrUpgradeAdmin');
        const result = await createOrUpgradeAdmin({ email: email, password: password });

        if (result.data.success) {
            statusMessageDiv.className = 'alert alert-success';
            statusMessageDiv.textContent = result.data.message || 'Admin processed successfully!';
            emailInput.value = ''; // Clear form
            passwordInput.value = '';
        } else {
            statusMessageDiv.className = 'alert alert-danger';
            statusMessageDiv.textContent = result.data.message || 'Failed to process admin request.';
        }
    } catch (error) {
        console.error("Error processing admin request:", error);
        statusMessageDiv.className = 'alert alert-danger';
        statusMessageDiv.textContent = `Error: ${error.message}`;
    }
});

function showStatusMessage(message, type) {
    const statusDiv = document.getElementById('action-status-message');
    statusDiv.textContent = message;
    statusDiv.className = `alert alert-${type}`; // e.g., 'alert-success', 'alert-danger', 'alert-info'
    statusDiv.style.display = 'block';
    setTimeout(() => {
        statusDiv.style.display = 'none';
    }, 5000); // Hide after 5 seconds
}

// Simple avatar generation (you might have a more robust one)
function getAvatarInitial(name, email) {
    if (name) return name.charAt(0).toUpperCase();
    if (email) return email.charAt(0).toUpperCase();
    return 'U';
}