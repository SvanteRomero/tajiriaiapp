// Your web app's Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyD7-wFvrOo2csO9N4EbFdeFe6xezJufVZ0",
  authDomain: "tajiri-ai-dev.firebaseapp.com",
  projectId: "tajiri-ai-dev",
  storageBucket: "tajiri-ai-dev.appspot.com",
  messagingSenderId: "143364800780",
  appId: "1:143364800780:web:9cc3a10310bbea9e000929",
  measurementId: "G-FWH0JYRX8Q"
};

// Initialize Firebase using the "compat" libraries
if (!firebase.apps.length) {
  firebase.initializeApp(firebaseConfig);
}