import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tajiri_ai/screens/auth/login_page.dart';
import 'package:tajiri_ai/core/utils/snackbar_utils.dart';
import 'package:tajiri_ai/core/services/notification_service.dart';

class EditProfilePage extends StatefulWidget {
  final User user;
  const EditProfilePage({super.key, required this.user});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  final TextEditingController _passwordController = TextEditingController();
  File? _imageFile;
  String? _networkImageUrl;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.displayName);
    _networkImageUrl = widget.user.photoURL;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 50);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      String? photoUrl = _networkImageUrl;

      if (_imageFile != null) {
        // --- THIS IS THE FIX ---
        // Create a unique filename to avoid conflicts.
        final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        // Construct the path to match your new storage rules: `user_avatars/{userId}/{fileName}`
        final ref = FirebaseStorage.instance
            .ref()
            .child('user_avatars')
            .child(widget.user.uid) // The user-specific folder
            .child('$fileName.jpg'); // The unique file within that folder
        // --- END OF FIX ---

        await ref.putFile(_imageFile!);
        photoUrl = await ref.getDownloadURL();
      }

      await widget.user.updateDisplayName(_nameController.text);
      if (photoUrl != widget.user.photoURL) {
        await widget.user.updatePhotoURL(photoUrl);
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .set({
        'displayName': _nameController.text,
        'photoUrl': photoUrl,
      }, SetOptions(merge: true));

      if (mounted) {
        showCustomSnackbar(context, 'Profile updated successfully!');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        print("Error updating profile: $e");
        showCustomSnackbar(context, 'Failed to update profile. Please try again.',
            type: SnackbarType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteAccount() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'This action is irreversible. Are you sure you want to delete your account and all associated data?'),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Enter your password to confirm',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: widget.user.email!,
        password: _passwordController.text.trim(),
      );
      await widget.user.reauthenticateWithCredential(credential);

      await NotificationService().unsubscribeFromUserTopic(widget.user.uid);
      
      HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('deleteUserData');
      await callable.call();

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false,
        );
        showCustomSnackbar(context, 'Account deleted successfully.');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        showCustomSnackbar(context, e.message ?? 'An error occurred',
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
      appBar: AppBar(title: const Text("Edit Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildImagePicker(),
              const SizedBox(height: 30),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Display Name"),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Save Changes"),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _deleteAccount,
                  icon: const Icon(Icons.delete_forever),
                  label: const Text("Delete Account"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: _imageFile != null
                ? FileImage(_imageFile!)
                : (_networkImageUrl != null
                    ? NetworkImage(_networkImageUrl!)
                    : null) as ImageProvider?,
            child: _imageFile == null && _networkImageUrl == null
                ? const Icon(Icons.person, size: 60)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Theme.of(context).primaryColor,
              child: IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                onPressed: _pickImage,
              ),
            ),
          ),
        ],
      ),
    );
  }
}