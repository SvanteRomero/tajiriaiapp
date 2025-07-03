// Import the functions you need from the SDKs you need
import { initializeApp } from "https://www.gstatic.com/firebasejs/9.17.1/firebase-app.js";
import { getAuth } from "https://www.gstatic.com/firebasejs/9.17.1/firebase-auth.js";
import { getFirestore } from "https://www.gstatic.com/firebasejs/9.17.1/firebase-firestore.js";
import { getFunctions } from "https://www.gstatic.com/firebasejs/9.17.1/firebase-functions.js";

// TODO: Replace with your project's actual Firebase configuration
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

// Export the services you'll need in other files
export const auth = getAuth(app);
export const db = getFirestore(app);
export const functions = getFunctions(app);