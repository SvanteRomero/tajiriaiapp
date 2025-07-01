// lib/main.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tajiri_ai/core/constants/app_theme.dart';
import 'package:tajiri_ai/core/viewmodels/theme_provider.dart';
import '/features/advisor_chat/viewmodel/advisor_chat_viewmodel.dart';
import '/screens/auth/login_page.dart';
import '/screens/home_page.dart';
import 'core/services/notification_service.dart';
import 'firebase_options.dart';

// Define the GlobalKey for the navigator
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Handler for background FCM messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  // Ensure that Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize the notification service
  await NotificationService().initialize(navigatorKey);

  // Enable Firestore offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Activate App Check for security
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );

  runApp(
    MultiProvider(
      providers: [
        // Provides the AI chat functionality
        ChangeNotifierProvider(create: (_) => AdvisorChatViewModel()),
        // Provides the theme (light/dark mode) functionality
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const TajiriAiApp(),
    ),
  );
}

class TajiriAiApp extends StatelessWidget {
  const TajiriAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch for theme changes here
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      navigatorKey: navigatorKey, // Set the navigator key
      title: 'Tajiri AI',
      debugShowCheckedModeBanner: false,
      // Apply the light and dark themes
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      // Use the current theme mode from the provider
      themeMode: themeProvider.themeMode,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          if (authSnapshot.hasData) {
            return HomePage(user: authSnapshot.data!);
          }
          return const LoginPage();
        },
      ),
    );
  }
}