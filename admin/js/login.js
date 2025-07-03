document.addEventListener('DOMContentLoaded', () => {
    const loginForm = document.getElementById('login-form');
    loginForm.addEventListener('submit', (e) => {
        e.preventDefault();
        const email = loginForm.email.value;
        const password = loginForm.password.value;
        firebase.auth().signInWithEmailAndPassword(email, password)
            .then(userCredential => {
                window.location.href = '/dashboard.html';
            })
            .catch(error => {
                document.getElementById('error-message').textContent = error.message;
                document.getElementById('error-message').style.display = 'block';
            });
    });
});