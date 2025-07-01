// lib/screens/edit_profile_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '/core/utils/snackbar_utils.dart';

//import 'package:google_fonts/google_fonts.dart';

class EditProfilePage extends StatefulWidget {
  final User user;
  const EditProfilePage({super.key, required this.user});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.displayName);
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        String? photoUrl = widget.user.photoURL;
        if (_imageFile != null) {
          final ref = FirebaseStorage.instance.ref().child('user_avatars').child('${widget.user.uid}.jpg');
          await ref.putFile(_imageFile!);
          photoUrl = await ref.getDownloadURL();
        }

        await widget.user.updateDisplayName(_nameController.text);
        if(photoUrl != widget.user.photoURL) {
          await widget.user.updatePhotoURL(photoUrl);
        }

        await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).set({
          'displayName': _nameController.text,
          'photoUrl': photoUrl,
          'email': widget.user.email,
        }, SetOptions(merge: true));

        if (mounted) {
          showCustomSnackbar(context, 'Profile updated successfully!');
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if(mounted) {
          showCustomSnackbar(context, 'Failed to update profile. Please try again.', type: SnackbarType.error);
        }
      } finally {
        if(mounted) {
          setState(() => _isLoading = false);
        }
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
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Save Changes"),
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
                : (widget.user.photoURL != null ? NetworkImage(widget.user.photoURL!) : null) as ImageProvider?,
            child: _imageFile == null && widget.user.photoURL == null ? const Icon(Icons.person, size: 60) : null,
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