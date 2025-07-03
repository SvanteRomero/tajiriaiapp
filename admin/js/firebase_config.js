// Import the functions you need from the SDKs you need
import { initializeApp } from "https://www.gstatic.com/firebasejs/11.10.0/firebase-app.js";
import { getAnalytics } from "https://www.gstatic.com/firebasejs/11.10.0/firebase-analytics.js";
// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyD7-wFvrOo2csO9N4EbFdeFe6xezJufVZ0",
  authDomain: "tajiri-ai-dev.firebaseapp.com",
  projectId: "tajiri-ai-dev",
  storageBucket: "tajiri-ai-dev.firebasestorage.app",
  messagingSenderId: "143364800780",
  appId: "1:143364800780:web:9cc3a10310bbea9e000929",
  measurementId: "G-FWH0JYRX8Q"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);