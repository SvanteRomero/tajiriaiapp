// lib/screens/profile_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'edit_profile_page.dart';
import 'package:tajiri_ai/screens/auth/login_page.dart'; // Import the login page

class ProfilePage extends StatefulWidget {
  final User user;
  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late User _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
  }

  Future<void> _refreshUser() async {
    await FirebaseAuth.instance.currentUser?.reload();
    if (mounted) {
      setState(() {
        _currentUser = FirebaseAuth.instance.currentUser!;
      });
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      // This will clear the entire navigation stack and push the LoginPage,
      // ensuring the user can't go back to a page that requires authentication.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                    builder: (_) => EditProfilePage(user: _currentUser)),
              );
              if (result == true) {
                _refreshUser();
              }
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 50,
              backgroundImage: _currentUser.photoURL != null
                  ? NetworkImage(_currentUser.photoURL!)
                  : null,
              child: _currentUser.photoURL == null
                  ? const Icon(Icons.person, size: 50)
                  : null,
            ),
            const SizedBox(height: 20),
            Text(_currentUser.displayName ?? 'No Name',
                style: GoogleFonts.poppins(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            Text(_currentUser.email ?? 'No Email',
                style: GoogleFonts.poppins(
                    fontSize: 16, color: Colors.grey.shade600)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400),
                onPressed: _signOut, // Updated to call the new _signOut method
                child: const Text("Sign Out"),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}