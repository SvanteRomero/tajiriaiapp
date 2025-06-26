// lib/screens/profile_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '/core/data/currencies.dart';
import '/core/models/account_model.dart';
import '/core/services/firestore_service.dart';
import 'add_goal_page.dart';
import 'edit_profile_page.dart';
import 'package:tajiri_ai/screens/auth/login_page.dart';
import 'edit_account_page.dart';
import 'manage_categories_page.dart';

class ProfilePage extends StatefulWidget {
  final User user;
  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late User _currentUser;
  final FirestoreService _firestoreService = FirestoreService();

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
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  void _showAddAccountDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController balanceController = TextEditingController();
    final _formKey = GlobalKey<FormState>();
    String selectedCurrency = 'USD'; // Default currency

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( // Use StatefulBuilder to update state inside the dialog
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Account'),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration:
                            const InputDecoration(labelText: 'Account Name'),
                        validator: (value) =>
                            value!.isEmpty ? 'Please enter a name' : null,
                      ),
                      TextFormField(
                        controller: balanceController,
                        decoration:
                            const InputDecoration(labelText: 'Initial Balance'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value!.isEmpty) return 'Please enter a balance';
                          if (double.tryParse(value) == null)
                            return 'Invalid number';
                          return null;
                        },
                      ),
                      DropdownButtonFormField<String>(
                        value: selectedCurrency,
                        decoration: const InputDecoration(labelText: 'Currency'),
                        items: currencies.keys.map((String key) {
                          return DropdownMenuItem<String>(
                            value: key,
                            child: Text(key),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedCurrency = newValue;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final newAccount = Account(
                        id: '', // Firestore will generate this
                        name: nameController.text,
                        balance: double.parse(balanceController.text),
                        currency: selectedCurrency,
                      );
                      _firestoreService.addAccount(_currentUser.uid, newAccount);
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _navigateToAddGoalPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddGoalPage(user: widget.user),
      ),
    );
  }

  void _navigateToManageCategoriesPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ManageCategoriesPage(user: widget.user),
      ),
    );
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
      body: SingleChildScrollView(
        child: Padding(
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
              const SizedBox(height: 24),
              const Divider(),
              const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text("Accounts",
                        style:
                            TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  )),
              SizedBox(
                height: 200, // Give the ListView a fixed height
                child: _buildAccountsList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showAddAccountDialog,
                  icon: const Icon(Icons.add),
                  label: const Text("Add Account"),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _navigateToAddGoalPage,
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text("Add New Goal"),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _navigateToManageCategoriesPage,
                  icon: const Icon(Icons.category_outlined),
                  label: const Text("Manage Categories"),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400),
                  onPressed: _signOut,
                  child: const Text("Sign Out"),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAccountsList() {
    return StreamBuilder<List<Account>>(
      stream: _firestoreService.getAccounts(_currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final accounts = snapshot.data!;
        if (accounts.isEmpty) {
          return const Center(child: Text("No accounts found."));
        }
        return ListView.builder(
          shrinkWrap: true, // Important for nested lists
          itemCount: accounts.length,
          itemBuilder: (context, index) {
            final account = accounts[index];
            return Card(
              child: ListTile(
                title: Text(account.name),
                trailing: Text(
                  NumberFormat.currency(
                    symbol: account.currency, // Use the account's currency
                    decimalDigits: 2,
                  ).format(account.balance),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  final bool? result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditAccountPage(user: widget.user, account: account),
                    ),
                  );
                  if (result == true) {
                    setState(() {});
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}