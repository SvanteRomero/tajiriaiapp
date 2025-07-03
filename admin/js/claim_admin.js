document.addEventListener('DOMContentLoaded', () => {
    const claimBtn = document.getElementById('claim-btn');
    const statusDiv = document.getElementById('status-message');

    firebase.auth().onAuthStateChanged(user => {
        if (user) {
            statusDiv.textContent = `Logged in as ${user.email}. Ready to claim.`;
            statusDiv.className = 'status-message';
            statusDiv.style.display = 'block';
            claimBtn.textContent = 'Claim Admin Role';
            claimBtn.disabled = false;
        } else {
            statusDiv.textContent = 'You must be logged in to claim this role.';
            statusDiv.className = 'status-message status-error';
            statusDiv.style.display = 'block';
        }
    });

    claimBtn.addEventListener('click', () => {
        claimBtn.disabled = true;
        claimBtn.textContent = 'Claiming...';
        const claimFirstAdmin = firebase.functions().httpsCallable('claimFirstAdmin');
        claimFirstAdmin().then(result => {
            alert(result.data.message + ' Refreshing session...');
            return firebase.auth().currentUser.getIdToken(true);
        }).then(() => {
            window.location.href = '/dashboard.html';
        }).catch(error => {
            statusDiv.textContent = error.message;
            statusDiv.className = 'status-message status-error';
            claimBtn.disabled = false;
            claimBtn.textContent = 'Try Again';
        });
    });
});