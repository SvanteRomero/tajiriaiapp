// lib/screens/edit_account_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/core/data/currencies.dart';
import '/core/models/account_model.dart';
import '/core/services/firestore_service.dart';
import '/core/utils/snackbar_utils.dart';
import 'package:google_fonts/google_fonts.dart';

class EditAccountPage extends StatefulWidget {
  final User user;
  final Account account; // The account to be edited

  const EditAccountPage({Key? key, required this.user, required this.account}) : super(key: key);

  @override
  State<EditAccountPage> createState() => _EditAccountPageState();
}

class _EditAccountPageState extends State<EditAccountPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _balanceController;
  late String _selectedCurrency;
  bool _isLoading = false;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account.name);
    _balanceController = TextEditingController(text: widget.account.balance.toStringAsFixed(2));
    _selectedCurrency = widget.account.currency;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedAccount = Account(
        id: widget.account.id,
        name: _nameController.text.trim(),
        balance: double.parse(_balanceController.text),
        currency: _selectedCurrency,
      );

      await _firestoreService.updateAccount(widget.user.uid, updatedAccount);
      if (mounted) {
        showCustomSnackbar(context, 'Account updated successfully!');
        Navigator.of(context).pop(true); // Pop with true to indicate success
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackbar(context, 'Failed to update account. Please try again.', type: SnackbarType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteAccount() async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Account?"),
        content: Text("Are you sure you want to delete '${widget.account.name}'? This action cannot be undone, and all associated transactions will be affected."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      setState(() => _isLoading = true);
      try {
        await _firestoreService.deleteAccount(widget.user.uid, widget.account.id);
        if (mounted) {
          showCustomSnackbar(context, 'Account deleted successfully!');
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          showCustomSnackbar(context, 'Failed to delete account. Please try again.', type: SnackbarType.error);
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Account"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            tooltip: "Delete Account",
            onPressed: _isLoading ? null : _deleteAccount,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text("Account Details", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Account Name"),
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _balanceController,
                decoration: InputDecoration(labelText: "Current Balance", prefixText: "$_selectedCurrency "),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a balance';
                  if (double.tryParse(value) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCurrency,
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
                      _selectedCurrency = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Save Changes"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}