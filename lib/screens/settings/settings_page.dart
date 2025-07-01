// lib/screens/settings_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tajiri_ai/core/viewmodels/theme_provider.dart';
import 'package:tajiri_ai/screens/auth/login_page.dart';
import 'package:tajiri_ai/screens/edit/edit_profile_page.dart';
import 'package:tajiri_ai/screens/manage/manage_categories_page.dart';
import 'package:tajiri_ai/screens/settings/notification_settings_page.dart';

class SettingsPage extends StatelessWidget {
  final User user;

  const SettingsPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Settings", style: GoogleFonts.poppins()),
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        children: [
          _buildSectionHeader("Account"),
          _buildSettingsTile(
            context,
            icon: Icons.person_outline,
            title: "Edit Profile",
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EditProfilePage(user: user),
                ),
              );
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.category_outlined,
            title: "Manage Categories",
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ManageCategoriesPage(user: user),
                ),
              );
            },
          ),
          const Divider(indent: 16, endIndent: 16),
          _buildSectionHeader("Preferences"),
          _buildSettingsTile(
            context,
            icon: Icons.notifications_outlined,
            title: "Notifications",
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NotificationSettingsPage(),
                ),
              );
            },
          ),
          SwitchListTile(
            title: const Text("Dark Mode"),
            value: themeProvider.themeMode == ThemeMode.dark,
            onChanged: (value) {
              themeProvider.toggleTheme();
            },
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (Route<dynamic> route) => false,
                  );
                }
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.red.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Sign Out',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context,
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title, style: GoogleFonts.poppins(fontSize: 16)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}