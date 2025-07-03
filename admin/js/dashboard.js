import { auth, db, functions } from './firebase-config.js';
import { onAuthStateChanged, signOut } from "https://www.gstatic.com/firebasejs/9.17.1/firebase-auth.js";
import { collection, getDocs, query, orderBy } from "https://www.gstatic.com/firebasejs/9.17.1/firebase-firestore.js";

// --- AUTH GUARD ---
onAuthStateChanged(auth, user => {
    if (user) {
        user.getIdTokenResult(true).then(idTokenResult => {
            if (idTokenResult.claims.admin) {
                document.body.style.visibility = 'visible';
                initializeDashboard();
            } else {
                alert('You do not have permission to access this page.');
                window.location.href = '/login.html';
            }
        });
    } else {
        window.location.href = '/login.html';
    }
});

function initializeDashboard() {
    console.log("Admin Dashboard Initialized");
    loadUsers();
    // Placeholder for loading other dashboard data
}

// --- DATA FETCHING & RENDERING ---
async function loadUsers() {
    const tbody = document.getElementById('user-table-body');
    if (!tbody) return;

    try {
        const usersQuery = query(collection(db, "users"), orderBy("email"));
        const querySnapshot = await getDocs(usersQuery);
        let userHtml = '';
        querySnapshot.forEach(doc => {
            const user = doc.data();
            userHtml += `
                <tr>
                    <td>${user.displayName || 'N/A'}</td>
                    <td>${user.email}</td>
                    <td>${new Date(user.createdAt.seconds * 1000).toLocaleDateString()}</td>
                    <td>--</td>
                    <td class="table-actions">
                        <button class="btn btn-secondary">View</button>
                    </td>
                </tr>
            `;
        });
        tbody.innerHTML = userHtml;
    } catch (error) {
        console.error("Error loading users:", error);
        tbody.innerHTML = '<tr><td colspan="5">Error loading users.</td></tr>';
    }
}

// --- LOGOUT ---
document.getElementById('logout-btn').addEventListener('click', () => {
    signOut(auth);
});