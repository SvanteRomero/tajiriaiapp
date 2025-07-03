// admin/js/login.js
const loginForm = document.getElementById('login-form');
const loginBtn = document.getElementById('login-btn');
const errorMessage = document.getElementById('error-message');
const auth = firebase.auth();

loginForm.addEventListener('submit', (e) => {
    e.preventDefault();
    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;

    loginBtn.disabled = true;
    loginBtn.textContent = 'Signing In...';
    errorMessage.style.display = 'none';

    auth.signInWithEmailAndPassword(email, password)
        .then(userCredential => {
            // User signed in, now check for admin claim
            return userCredential.user.getIdTokenResult(true);
        })
        .then(idTokenResult => {
            if (!!idTokenResult.claims.admin) {
                // It's an admin! Redirect to the dashboard.
                window.location.href = '/admin.html';
            } else {
                // Not an admin. Sign them out and show an error.
                auth.signOut();
                showError('Access Denied. You are not an administrator.');
            }
        })
        .catch(error => {
            showError(error.message);
        })
        .finally(() => {
            loginBtn.disabled = false;
            loginBtn.textContent = 'Login';
        });
});

function showError(message) {
    errorMessage.textContent = message;
    errorMessage.className = 'status-message status-error';
    errorMessage.style.display = 'block';
}