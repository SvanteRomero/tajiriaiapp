import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/profile_card.dart';
import '../widgets/goal_progress.dart';
import '../services/offline_storage_service.dart';

class ProfilePageUpdated extends StatefulWidget {
  final User user;
  
  const ProfilePageUpdated({
    Key? key, 
    required this.user,
  }) : super(key: key);

  @override
  State<ProfilePageUpdated> createState() => _ProfilePageUpdatedState();
}

class _ProfilePageUpdatedState extends State<ProfilePageUpdated> {
  final OfflineStorageService _storageService = OfflineStorageService();
  final ImagePicker _picker = ImagePicker();
  
  bool _isLoading = true;
  String _errorMessage = '';
  
  // User profile information
  String _name = '';
  String _email = '';
  String _phone = '';
  String? _photoUrl;
  String _occupation = '';

  // Financial overview
  double _balance = 0;
  double _totalIncome = 0;
  double _totalExpense = 0;

  // Category totals
  Map<String, double> _incomeCategoryTotals = {};
  Map<String, double> _expenseCategoryTotals = {};

  // Savings goals
  String _goalTitle = '';
  double _goalTarget = 5000.0; // Default target
  DateTime? _goalDeadline;
  double _goalProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Initialize storage service
      await _storageService.initialize().catchError((e) {
        throw 'Failed to initialize storage: $e';
      });

      // Load offline transactions
      final transactions = _storageService.getTransactions(widget.user.uid);
      
      // Calculate totals
      double income = 0, expense = 0;
      _incomeCategoryTotals = {};
      _expenseCategoryTotals = {};

      for (var tx in transactions) {
        if (tx.type == 'income') {
          income += tx.amount;
          _incomeCategoryTotals[tx.mainCategory] = 
              (_incomeCategoryTotals[tx.mainCategory] ?? 0) + tx.amount;
        } else {
          expense += tx.amount;
          _expenseCategoryTotals[tx.mainCategory] = 
              (_expenseCategoryTotals[tx.mainCategory] ?? 0) + tx.amount;
        }
      }

      // Load user profile from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        _name = data['name'] as String? ?? widget.user.displayName ?? '';
        _email = data['email'] as String? ?? widget.user.email ?? '';
        _phone = data['phone'] as String? ?? '';
        _photoUrl = data['photoUrl'] as String?;
        _occupation = data['occupation'] as String? ?? '';
      }

      // Load active goal
      final goalsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .collection('goals')
          .where('isActive', isEqualTo: true)
          .get();

      if (goalsSnapshot.docs.isNotEmpty) {
        final goalData = goalsSnapshot.docs.first.data();
        _goalTitle = goalData['title'] as String? ?? '';
        _goalTarget = (goalData['target'] as num?)?.toDouble() ?? 5000.0;
        _goalDeadline = (goalData['deadline'] as Timestamp?)?.toDate();
      }

      // Calculate current balance and goal progress
      _balance = income - expense;
      if (_goalTarget > 0) {
        _goalProgress = (_balance / _goalTarget).clamp(0.0, 1.0);
      }

      setState(() {
        _totalIncome = income;
        _totalExpense = expense;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load profile data: $e';
      });
    }
  }

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  String _getRemainingDays() {
    if (_goalDeadline == null) return '30 days remaining';
    
    final remaining = _goalDeadline!.difference(DateTime.now()).inDays;
    if (remaining < 0) {
      return '${-remaining} days overdue';
    }
    return '$remaining days remaining';
  }

  Widget _buildCategoryBreakdown() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            // Income Categories
            const Text(
              'Income Categories',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            ..._buildCategoryList(_incomeCategoryTotals, Colors.green.shade700),
            const SizedBox(height: 16),
            // Expense Categories
            const Text(
              'Expense Categories',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            ..._buildCategoryList(_expenseCategoryTotals, Colors.red.shade700),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCategoryList(Map<String, double> categories, Color color) {
    final sortedCategories = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedCategories.map((entry) {
      final total = color == Colors.green.shade700 ? _totalIncome : _totalExpense;
      final percentage = total > 0 
          ? ((entry.value / total) * 100).toStringAsFixed(1)
          : '0.0';
      
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(Icons.circle, size: 12, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.key,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Text(
              _formatCurrency(entry.value),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.grey[50],
    appBar: AppBar(
      title: const Text('Profile'),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
    ),
    body: RefreshIndicator(
      onRefresh: _initializeData,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage.isNotEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _initializeData,
                            color: Colors.red.shade700,
                          ),
                        ],
                      ),
                    ),

                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(),
                    )
                  else ...[
                    ProfileCard(
                      displayName: _name,
                      occupation: _occupation,
                      balance: _balance,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile details coming soon!'),
                          ),
                        );
                      },
                      formatCurrency: _formatCurrency,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF1976D2),
                            const Color(0xFF1976D2).withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: GoalProgress(
                        title: _goalTitle.isEmpty ? 'Savings Goal' : _goalTitle,
                        progress: _goalProgress,
                        target: _goalTarget,
                        remainingDays: _getRemainingDays(),
                        formatCurrency: _formatCurrency,
                        onEditPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Goal editing coming soon!'),
                            ),
                          );
                        },
                        onBudgetPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Budget management coming soon!'),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildCategoryBreakdown(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  @override
  void dispose() {
    _storageService.dispose();
    super.dispose();
  }
}
