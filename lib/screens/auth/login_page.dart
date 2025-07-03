import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tajiri_ai/screens/home_page.dart';
import 'package:tajiri_ai/screens/auth/register_page.dart';
import 'package:tajiri_ai/core/utils/snackbar_utils.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  /// Handles the user sign-in process.
  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // On successful login, navigate to the HomePage.
      if (mounted && userCredential.user != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => HomePage(
              user: userCredential.user!,
              // Explicitly false for existing users to prevent re-triggering the welcome notification.
              isNewUser: false,
            ),
          ),
          (Route<dynamic> route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        showCustomSnackbar(context, e.message ?? "Authentication failed",
            type: SnackbarType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Welcome Back!",
                    style: GoogleFonts.poppins(
                        fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("Sign in to continue",
                    style: GoogleFonts.poppins(
                        fontSize: 16, color: Colors.grey.shade600)),
                const SizedBox(height: 40),
                TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: "Email"),
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: "Password")),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Sign In"),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const RegisterPage())),
                      child: const Text("Sign Up"),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}