// Import required Firebase packages for authentication, core functionality, and storage
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'services/offline_storage_service.dart';

// Import application pages
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';

/// Entry point of the application
/// Initializes Firebase and required services before launching the app
void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize offline storage first
  final offlineStorage = OfflineStorageService();
  await offlineStorage.initialize();

  // Initialize Firebase core functionality
  await Firebase.initializeApp();

  // Initialize Firebase App Check for security
  // Uses debug providers during development
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  // Enable Firebase Auth persistence and initialize Auth
  await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  
  // Initialize Firebase services:
  // - Authentication for user management
  // - Firestore for database operations
  // - Storage for file handling
  FirebaseAuth.instance;
  FirebaseFirestore.instance;
  FirebaseStorage.instance;

  // Launch the application
  runApp(const TajiriAiApp());
}

/// Root widget of the Tajiri AI application
/// Handles routing and authentication state management
class TajiriAiApp extends StatelessWidget {
  const TajiriAiApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<OfflineStorageService>(
          create: (_) => OfflineStorageService(),
          dispose: (_, service) => service.dispose(),
        ),
      ],
      child: MaterialApp(
        title: 'Tajiri AI',
        debugShowCheckedModeBanner: false,
        // Define named routes for navigation
        routes: {
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
        },
        // StreamBuilder listens to authentication state changes
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            // Show loading indicator while checking auth state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            // Navigate to HomePage if user is authenticated
            if (snapshot.hasData) {
              return HomePage(user: snapshot.data!);
            }
            // Show LoginPage if user is not authenticated
            return const LoginPage();
          },
        ),
      ),
    );
  }
}
