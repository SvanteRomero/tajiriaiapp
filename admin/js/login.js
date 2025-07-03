import { auth, functions } from './firebase-config.js';
import { signInWithEmailAndPassword, signOut } from "https://www.gstatic.com/firebasejs/9.17.1/firebase-auth.js";
import { httpsCallable } from "https://www.gstatic.com/firebasejs/9.17.1/firebase-functions.js";

document.addEventListener('DOMContentLoaded', () => {
    const loginForm = document.getElementById('login-form');
    const errorMessageDiv = document.getElementById('error-message');
    const submitBtn = loginForm.querySelector('button[type="submit"]');

    loginForm.addEventListener('submit', (e) => {
        e.preventDefault();
        const email = loginForm.email.value;
        const password = loginForm.password.value;

        // Disable button and clear previous errors
        submitBtn.disabled = true;
        submitBtn.textContent = 'Logging In...';
        errorMessageDiv.style.display = 'none';

        signInWithEmailAndPassword(auth, email, password)
            .then(async (userCredential) => {
                // Step 1: User is signed in. Now check their status.
                submitBtn.textContent = 'Checking Permissions...';
                
                const checkUserStatus = httpsCallable(functions, 'checkUserStatus');
                const result = await checkUserStatus();
                const status = result.data.status;

                // Step 2: Redirect based on the status returned by the cloud function
                if (status === 'admin') {
                    window.location.href = '/dashboard.html';
                } else if (status === 'can-claim') {
                    window.location.href = '/claim_admin.html';
                } else { // 'non-admin' or any other case
                    errorMessageDiv.textContent = 'This account does not have admin permissions.';
                    errorMessageDiv.style.display = 'block';
                    submitBtn.disabled = false;
                    submitBtn.textContent = 'Login';
                    // Log the user out as they have no access
                    await signOut(auth);
                }
            })
            .catch((error) => {
                // Handle login errors (e.g., wrong password)
                errorMessageDiv.textContent = error.message;
                errorMessageDiv.style.display = 'block';
                submitBtn.disabled = false;
                submitBtn.textContent = 'Login';
            });
    });
});