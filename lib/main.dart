import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tajiri_ai/pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    TajiriAiApp(),
  );
}

class TajiriAiApp extends StatelessWidget {
  const TajiriAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      routes: {'/loginpage': (context) => const LoginPage(),
        '/registerpage': (context) => const RegisterPage(),
        '/homepage': (context) => const HomePage(),
      },
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(),
    );
  }}
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // or a splash screen
        }

        if (snapshot.hasData) {
          // User is logged in
          return HomePage();
        } else {
          // User is not logged in
          return LoginPage();
        }
      },
    );
  }
}

