document.addEventListener('DOMContentLoaded', () => {
    const signupForm = document.getElementById('signup-form');
    signupForm.addEventListener('submit', (e) => {
        e.preventDefault();
        const displayName = signupForm.displayName.value;
        const email = signupForm.email.value;
        const password = signupForm.password.value;

        firebase.auth().createUserWithEmailAndPassword(email, password)
            .then(userCredential => {
                return userCredential.user.updateProfile({ displayName: displayName });
            })
            .then(() => {
                alert("Account created! Please log in to continue.");
                window.location.href = '/login.html';
            })
            .catch(error => {
                document.getElementById('error-message').textContent = error.message;
                document.getElementById('error-message').style.display = 'block';
            });
    });
});