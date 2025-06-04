/// Entry point for the Tajiri AI application.
/// This file initializes Firebase services and sets up the root widget.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';

/// Application entry point.
/// Initializes Firebase and other required services before running the app.
void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase core functionality
  await Firebase.initializeApp();

  // Initialize Firebase App Check for security
  // Uses debug providers during development
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  // Initialize Firebase services
  // These are initialized here to ensure they're ready when needed
  FirebaseAuth.instance;
  FirebaseFirestore.instance;
  FirebaseStorage.instance;

  // Launch the application
  runApp(const TajiriAiApp());
}

/// Root widget of the Tajiri AI application.
/// 
/// This widget:
/// - Sets up the MaterialApp configuration
/// - Defines the app's routes
/// - Handles authentication state changes
/// - Manages initial route based on auth state
class TajiriAiApp extends StatelessWidget {
  const TajiriAiApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tajiri AI',
      debugShowCheckedModeBanner: false,

      // Define named routes for navigation
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
      },

      // Home widget with authentication state management
      home: StreamBuilder<User?>(
        // Listen to authentication state changes
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Show loading indicator while checking auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // If user is authenticated, show HomePage
          if (snapshot.hasData) {
            return HomePage(user: snapshot.data!);
          }

          // If user is not authenticated, show LoginPage
          return const LoginPage();
        },
      ),
    );
  }
}
