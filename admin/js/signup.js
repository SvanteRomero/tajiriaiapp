import { auth } from './firebase-config.js';
import { createUserWithEmailAndPassword, updateProfile } from "https://www.gstatic.com/firebasejs/9.17.1/firebase-auth.js";

document.addEventListener('DOMContentLoaded', () => {
    const signupForm = document.getElementById('signup-form');
    const errorMessageDiv = document.getElementById('error-message');

    signupForm.addEventListener('submit', (e) => {
        e.preventDefault();
        const displayName = signupForm.displayName.value;
        const email = signupForm.email.value;
        const password = signupForm.password.value;

        createUserWithEmailAndPassword(auth, email, password)
            .then((userCredential) => {
                // Set the user's display name
                return updateProfile(userCredential.user, { displayName: displayName });
            })
            .then(() => {
                alert("Account created! Redirecting to login page.");
                window.location.href = '/login.html';
            })
            .catch((error) => {
                errorMessageDiv.textContent = error.message;
                errorMessageDiv.style.display = 'block';
            });
    });
});