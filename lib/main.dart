// lib/main.dart
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tajiri_ai/features/advisor_chat/viewmodel/advisor_chat_viewmodel.dart';
import 'package:tajiri_ai/screens/auth/login_page.dart';
import 'package:tajiri_ai/screens/home_page.dart';
import 'firebase_options.dart';

// This is the new, recommended way to initialize Firebase.
// We create a Future that will complete when Firebase is ready.
final firebaseInitialization = Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
).then((app) {
  // Activate App Check after Firebase is initialized.
  return FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );
});


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // No need to await Firebase here anymore.
  // The FutureBuilder in the app will handle it.

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AdvisorChatViewModel()),
      ],
      child: const TajiriAiApp(),
    ),
  );
}

class TajiriAiApp extends StatelessWidget {
  const TajiriAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    // This variable gets the default text theme of the app.
    final textTheme = Theme.of(context).textTheme;
    
    return MaterialApp(
      title: 'Tajiri AI',
      debugShowCheckedModeBanner: false,
      // The theme is now fully implemented using the variables.
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        // Here, GoogleFonts is used to apply the 'Poppins' font to the default text theme.
        textTheme: GoogleFonts.poppinsTextTheme(textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        scaffoldBackgroundColor: Colors.grey[50],
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade200,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold)
          )
        )
      ),
      home: FutureBuilder(
        // Use the Future we created earlier.
        future: firebaseInitialization,
        builder: (context, snapshot) {
          // While Firebase is initializing, show a loading screen.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text("Connecting to services..."),
                  ],
                ),
              ),
            );
          }

          // If there was an error during initialization, show it.
          if (snapshot.hasError) {
             return Scaffold(
              body: Center(
                child: Text("Error initializing Firebase: ${snapshot.error}"),
              ),
            );
          }
          
          // Once initialization is complete, show the auth state stream.
          return StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, authSnapshot) {
              if (authSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              if (authSnapshot.hasData) {
                return HomePage(user: authSnapshot.data!);
              }
              return const LoginPage();
            },
          );
        },
      ),
    );
  }
}