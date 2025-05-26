import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  final User user;
  const ProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  String _name = '';
  String _email = '';
  String _phone = '';
  String? _photoUrl;
  double _balance = 0;
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _weeklyGoal = 0;
  double _monthlyGoal = 0;
  String _goalTitle = '';
  double _goalTarget = 0;
  DateTime? _goalDeadline;
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Load user document
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.user.uid)
              .get();

      if (!mounted) return;

      if (userDoc.exists) {
        final data = userDoc.data()!;
        setState(() {
          _name = data['name'] as String? ?? widget.user.displayName ?? '';
          _email = data['email'] as String? ?? widget.user.email!;
          _phone = data['phone'] as String? ?? '';
          _photoUrl = data['photoUrl'] as String?;
          _weeklyGoal = (data['weeklyGoal'] as num?)?.toDouble() ?? 0;
          _monthlyGoal = (data['monthlyGoal'] as num?)?.toDouble() ?? 0;
        });
      }

      // Load transactions
      final txSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.user.uid)
              .collection('transactions')
              .get();

      if (!mounted) return;

      double income = 0, expense = 0;
      for (var doc in txSnapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num).toDouble();
        if (data['type'] == 'income') {
          income += amount;
        } else {
          expense += amount;
        }
      }

      setState(() {
        _totalIncome = income;
        _totalExpense = expense;
        _balance = income - expense;
      });

      // Load active goal
      final goalsSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.user.uid)
              .collection('goals')
              .where('isActive', isEqualTo: true)
              .get();

      if (!mounted) return;

      if (goalsSnapshot.docs.isNotEmpty) {
        final goalData = goalsSnapshot.docs.first.data();
        setState(() {
          _goalTitle = goalData['title'] as String? ?? '';
          _goalTarget = (goalData['target'] as num?)?.toDouble() ?? 0;
          _goalDeadline = (goalData['deadline'] as Timestamp?)?.toDate();
        });
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading user data: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editProfile() async {
    String name = _name;
    String phone = _phone;

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Profile'),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: name,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator:
                        (v) => v == null || v.isEmpty ? 'Required' : null,
                    onSaved: (v) => name = v!.trim(),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: phone,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                    onSaved: (v) => phone = v?.trim() ?? '',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    _formKey.currentState!.save();
                    Navigator.pop(context);
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.user.uid)
                        .update({'name': name, 'phone': phone});
                    await _loadUserData();
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  Future<void> _pickOrChangePhoto() async {
    try {
      final action = await showModalBottomSheet<String>(
        context: context,
        builder:
            (_) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(_photoUrl == null ? 'Add Photo' : 'Change Photo'),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () => Navigator.pop(context, 'gallery'),
                ),
                if (_photoUrl != null)
                  ListTile(
                    leading: const Icon(Icons.delete),
                    title: const Text('Remove Photo'),
                    onTap: () => Navigator.pop(context, 'remove'),
                  ),
                ListTile(
                  leading: const Icon(Icons.close),
                  title: const Text('Cancel'),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
      );

      if (action == 'gallery') {
        final picked = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 70,
          maxWidth: 800,
          maxHeight: 800,
        );

        if (picked != null) {
          print('Image picked: ${picked.path}');
          await _uploadPhoto(File(picked.path));
        }
      } else if (action == 'remove') {
        await _removePhoto();
      }
    } catch (e) {
      print('Error picking photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick photo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadPhoto(File file) async {
    try {
      setState(() => _isLoading = true);

      // Create a simpler storage reference
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(widget.user.uid)
          .child('profile.jpg');

      // Upload the file with metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'picked-file-path': file.path},
      );

      // Upload the file
      final uploadTask = storageRef.putFile(file, metadata);

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        print(
          'Upload progress: ${snapshot.bytesTransferred}/${snapshot.totalBytes}',
        );
      });

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('Download URL: $downloadUrl');

      // Update user profile in Firebase Auth
      await widget.user.updatePhotoURL(downloadUrl);

      // Update user document in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .update({'photoUrl': downloadUrl});

      // Update local state
      if (mounted) {
        setState(() {
          _photoUrl = downloadUrl;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error uploading photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload photo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removePhoto() async {
    try {
      setState(() => _isLoading = true);

      // Delete the image from Firebase Storage
      if (_photoUrl != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('users')
            .child(widget.user.uid)
            .child('profile.jpg');

        try {
          await storageRef.delete();
        } catch (e) {
          print('Error deleting storage file: $e');
          // Continue with profile update even if storage delete fails
        }
      }

      // Update user profile in Firebase Auth
      await widget.user.updatePhotoURL(null);

      // Update user document in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .update({'photoUrl': FieldValue.delete()});

      // Update local state
      if (mounted) {
        setState(() {
          _photoUrl = null;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo removed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error removing photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove photo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _deleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (c) => AlertDialog(
            title: const Text('Delete Account?'),
            content: const Text('This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (ok == true) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .delete();
      await widget.user.delete();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  String _format(double val) =>
      NumberFormat.currency(symbol: 'Tsh ', decimalDigits: 0).format(val);

  Widget _buildSavingsOverviewCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Savings Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: _editSavingsDetails,
                ),
              ],
            ),
            const Divider(),
            if (_weeklyGoal > 0 || _monthlyGoal > 0) ...[
              _buildSavingsProgressItem(
                'Weekly Savings',
                _balance,
                _weeklyGoal,
                Icons.calendar_today,
              ),
              const SizedBox(height: 16),
              _buildSavingsProgressItem(
                'Monthly Savings',
                _balance,
                _monthlyGoal,
                Icons.calendar_month,
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'No savings goals set',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Set your weekly and monthly savings goals to track your progress',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _editSavingsDetails,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Savings Goals'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsProgressItem(
    String title,
    double current,
    double target,
    IconData icon,
  ) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final isOverdue = target > 0 && current < target;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isOverdue ? Colors.red.shade50 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: isOverdue ? Colors.red.shade700 : Colors.blue.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _format(current),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isOverdue ? Colors.red.shade700 : Colors.black87,
              ),
            ),
            Text(
              _format(target),
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: isOverdue ? Colors.red.shade200 : Colors.blue.shade200,
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor:
                  isOverdue ? Colors.red.shade50 : Colors.blue.shade50,
              color: isOverdue ? Colors.red.shade700 : Colors.blue.shade700,
              minHeight: 6,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _editSavingsDetails() async {
    String weeklyGoal = _weeklyGoal.toString();
    String monthlyGoal = _monthlyGoal.toString();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Savings Details'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: weeklyGoal,
                    decoration: const InputDecoration(
                      labelText: 'Weekly Savings Goal (Tsh)',
                    ),
                    keyboardType: TextInputType.number,
                    validator:
                        (v) =>
                            v == null || double.tryParse(v) == null
                                ? 'Enter valid number'
                                : null,
                    onSaved: (v) => weeklyGoal = v!,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: monthlyGoal,
                    decoration: const InputDecoration(
                      labelText: 'Monthly Savings Goal (Tsh)',
                    ),
                    keyboardType: TextInputType.number,
                    validator:
                        (v) =>
                            v == null || double.tryParse(v) == null
                                ? 'Enter valid number'
                                : null,
                    onSaved: (v) => monthlyGoal = v!,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState?.validate() ?? false) {
                    formKey.currentState!.save();
                    Navigator.pop(context);
                    setState(() => _isLoading = true);
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.user.uid)
                        .update({
                          'weeklyGoal': double.parse(weeklyGoal),
                          'monthlyGoal': double.parse(monthlyGoal),
                        });
                    await _loadUserData();
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  Future<void> _showComingSoonDialog() async {
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Coming Soon'),
            content: const Text(
              'This feature will be available in the next update!',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Widget _buildProfileAvatar() {
    return CircleAvatar(
      radius: 50,
      backgroundColor: Colors.white,
      backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
      child:
          _photoUrl == null
              ? const Icon(Icons.person, size: 50, color: Colors.blue)
              : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadUserData,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Profile Header
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.blue.shade700,
                              Colors.blue.shade500,
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                _buildProfileAvatar(),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.blue,
                                    ),
                                    onPressed: _pickOrChangePhoto,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _email,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Financial Stats
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 24,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Icon(
                                  Icons.account_balance_wallet,
                                  color: Colors.blue,
                                  size: 28,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _format(_balance),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Balance',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Icon(
                                  Icons.arrow_downward,
                                  color: Colors.green.shade700,
                                  size: 28,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _format(_totalIncome),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Income',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Icon(
                                  Icons.arrow_upward,
                                  color: Colors.red.shade700,
                                  size: 28,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _format(_totalExpense),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Expense',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Savings Overview Card
                    _buildSavingsOverviewCard(),
                    const SizedBox(height: 24),
                    // Budget Details Card
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Budget Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const Divider(),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Budget tracking coming soon',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Set and track your monthly budget categories',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _showComingSoonDialog,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add Budget Details'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Savings Goal
                    if (_goalTitle.isNotEmpty) ...[
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Current Goal',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () {
                                      // TODO: Implement goal editing
                                    },
                                  ),
                                ],
                              ),
                              const Divider(),
                              ListTile(
                                leading: const Icon(
                                  Icons.flag,
                                  color: Colors.blue,
                                ),
                                title: Text(_goalTitle),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      'Target: ${_format(_goalTarget)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    if (_goalDeadline != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Deadline: ${DateFormat('MMM d, y').format(_goalDeadline!)}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildSavingsProgressItem(
                                'Progress',
                                _balance,
                                _goalTarget,
                                Icons.flag,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    // Contact Info
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Contact Information',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: _editProfile,
                                ),
                              ],
                            ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(
                                Icons.person,
                                color: Colors.blue,
                              ),
                              title: const Text('Name'),
                              subtitle: Text(_name),
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.email,
                                color: Colors.blue,
                              ),
                              title: const Text('Email'),
                              subtitle: Text(_email),
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.phone,
                                color: Colors.blue,
                              ),
                              title: const Text('Phone'),
                              subtitle: Text(
                                _phone.isNotEmpty ? _phone : 'Not set',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Action Buttons
                    ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Log Out'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _deleteAccount,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        minimumSize: const Size.fromHeight(48),
                        side: BorderSide(color: Colors.red.shade700),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Delete Account'),
                    ),
                  ],
                ),
              ),
    );
  }
}
