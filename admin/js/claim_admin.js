// Import our configured services from the central config file
import { auth, functions } from './firebase-config.js';

// Import the specific functions we need from the Firebase SDK
import { onAuthStateChanged } from "https://www.gstatic.com/firebasejs/9.17.1/firebase-auth.js";
import { httpsCallable } from "https://www.gstatic.com/firebasejs/9.17.1/firebase-functions.js";

document.addEventListener('DOMContentLoaded', () => {
    const claimBtn = document.getElementById('claim-btn');
    const statusDiv = document.getElementById('status-message');

    // Listen for authentication state changes
    onAuthStateChanged(auth, user => {
        if (user) {
            // User is logged in
            statusDiv.textContent = `Logged in as ${user.email}. Ready to claim.`;
            statusDiv.className = 'status-message';
            statusDiv.style.display = 'block';
            claimBtn.textContent = 'Claim Admin Role';
            claimBtn.disabled = false;
        } else {
            // No user is logged in
            statusDiv.textContent = 'You must be logged in to claim this role. Please go back to the login page.';
            statusDiv.className = 'status-message status-error';
            statusDiv.style.display = 'block';
            claimBtn.disabled = true;
        }
    });

    claimBtn.addEventListener('click', () => {
        claimBtn.disabled = true;
        claimBtn.textContent = 'Claiming...';

        // Get a reference to the Cloud Function
        const claimFirstAdmin = httpsCallable(functions, 'claimFirstAdmin');

        // Call the function and handle the result
        claimFirstAdmin()
            .then(result => {
                alert(result.data.message + ' Refreshing session...');
                // Force a refresh of the user's ID token to get the new 'admin' claim
                return auth.currentUser.getIdToken(true);
            })
            .then(() => {
                // Redirect to the dashboard, where the admin claim will be recognized
                window.location.href = '/dashboard.html';
            })
            .catch(error => {
                // Display any errors from the Cloud Function
                statusDiv.textContent = `Error: ${error.message}`;
                statusDiv.className = 'status-message status-error';
                claimBtn.disabled = false;
                claimBtn.textContent = 'Try Again';
            });
    });
});