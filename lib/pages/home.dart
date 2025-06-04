/// A comprehensive dashboard page that displays user's financial information,
/// including current balance, savings goals, and transaction history.
/// This page integrates with Firebase Firestore for real-time data management
/// and provides interactive features for managing financial goals and transactions.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:tajiri_ai/pages/profile_page.dart';
import '../models/transaction.dart' as my_model;
import 'package:tajiri_ai/components/empty_page.dart';

/// The main dashboard widget that displays user's financial information and transactions.
/// Requires an authenticated user instance to function.
class Home extends StatefulWidget {
  final User user;
  const Home({Key? key, required this.user}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // Loading state flag
  bool _isLoading = true;
  
  // List to store user's transactions
  List<my_model.Transaction> _transactions = [];
  
  // User information
  String _displayName = '';
  String _occupation = '';
  int _age = 0;
  
  // Financial goal information
  String _goalTitle = '';
  int _goalTarget = 0;
  DateTime? _goalDeadline;
  double _goalProgress = 0;
  String? _currentGoalId;

  @override
  void initState() {
    super.initState();
    // Initialize by fetching all necessary data
    _fetchUserInfo();
    _fetchTransactions();
    _fetchCurrentGoal();
  }

  /// Fetches user's basic information from Firestore.
  /// Updates the UI with user's name, occupation, and age.
  Future<void> _fetchUserInfo() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            _displayName = data['name'] ?? '';
            _occupation = data['occupation'] ?? '';
            _age = data['age'] ?? 0;
          });
        }
      }
    } catch (_) {
      // Silently handle errors to prevent app crashes
    }
  }

  /// Fetches the user's current active financial goal from Firestore.
  /// Updates the UI with goal details and calculates progress.
  Future<void> _fetchCurrentGoal() async {
    try {
      print('Fetching goals for user: ${widget.user.uid}');
      final snapshot = await FirebaseFirestore.instance
          .collection('goals')
          .where('userId', isEqualTo: widget.user.uid)
          .where('status', isEqualTo: 'active')
          .get();

      print('Found ${snapshot.docs.length} active goals');

      if (snapshot.docs.isNotEmpty) {
        // Sort goals by deadline
        final sortedDocs = snapshot.docs.toList()
          ..sort((a, b) {
            final aDeadline = DateTime.parse(a['deadline'] as String);
            final bDeadline = DateTime.parse(b['deadline'] as String);
            return aDeadline.compareTo(bDeadline);
          });

        final goalData = sortedDocs.first;
        print('Goal data: ${goalData.data()}');

        setState(() {
          _currentGoalId = goalData.id;
          _goalTitle = goalData['title'] as String;
          _goalTarget = goalData['target'] as int;
          _goalDeadline = DateTime.parse(goalData['deadline'] as String);
          _goalProgress = 0; // Reset progress before calculation
        });

        print('Updated goal state: Title: $_goalTitle, Target: $_goalTarget');
        _calculateGoalProgress();
      } else {
        print('No active goals found');
        setState(() {
          _currentGoalId = null;
          _goalTitle = '';
          _goalTarget = 0;
          _goalDeadline = null;
          _goalProgress = 0;
        });
      }
    } catch (e) {
      print('Error fetching goal: $e');
      setState(() {
        _currentGoalId = null;
        _goalTitle = '';
        _goalTarget = 0;
        _goalDeadline = null;
        _goalProgress = 0;
      });
    }
  }

  /// Calculates the progress towards the current financial goal
  /// based on total savings (income - expenses).
  /// Shows a congratulatory dialog if the goal is achieved.
  void _calculateGoalProgress() {
    print('Calculating progress for goal: $_goalTitle');
    print('Current target: $_goalTarget');

    if (_goalTarget <= 0) {
      setState(() {
        _goalProgress = 0;
      });
      return;
    }

    // Calculate total savings
    double totalSavings = 0;
    for (var tx in _transactions) {
      if (tx.type == my_model.TransactionType.income) {
        totalSavings += tx.amount;
      } else {
        totalSavings -= tx.amount;
      }
    }

    print('Total savings: $totalSavings');
    print('Current balance: $_currentBalance');

    // Calculate progress percentage
    double newProgress = (totalSavings / _goalTarget).clamp(0, 1);
    print('Calculated progress: $newProgress');

    setState(() {
      _goalProgress = newProgress;
    });

    // Show achievement dialog if goal is reached
    if (newProgress >= 1.0) {
      _showGoalAchievedDialog();
    }
  }

  /// Displays a congratulatory dialog when a financial goal is achieved.
  /// Provides options to continue or set a new goal.
  void _showGoalAchievedDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1976D2),
                const Color(0xFF1976D2).withOpacity(0.8),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Achievement icon and title
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.celebration,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Goal Achieved!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Congratulations! You\'ve reached your goal: $_goalTitle',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              // ... Rest of the dialog implementation
            ],
          ),
        ),
      ),
    );
  }

  /// Shows a dialog for adding or editing a financial goal.
  /// Handles goal creation/update in Firestore.
  void _showAddNewGoalDialog() {
    final titleController = TextEditingController(text: _goalTitle);
    final amountController = TextEditingController(
      text: _goalTarget > 0 ? _goalTarget.toString() : '',
    );
    DateTime selectedDeadline = _goalDeadline ?? DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_goalTitle.isEmpty ? 'Set New Goal' : 'Edit Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Goal input fields
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Goal Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Target Amount (Tsh)',
                border: OutlineInputBorder(),
              ),
            ),
            // ... Rest of the dialog implementation
          ],
        ),
      ),
    );
  }

  /// Fetches user's transactions from Firestore.
  /// Updates the UI with transaction history and recalculates goal progress.
  Future<void> _fetchTransactions() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .collection('transactions')
          .orderBy('date', descending: true)
          .get();

      final transactions = snapshot.docs.map((doc) {
        final data = doc.data();
        final type = (data['type'] as String) == 'income'
            ? my_model.TransactionType.income
            : my_model.TransactionType.expense;
        return my_model.Transaction(
          username: data['username'] ?? '',
          description: data['description'] ?? '',
          amount: (data['amount'] as num).toDouble(),
          date: (data['date'] as Timestamp).toDate(),
          type: type,
        );
      }).toList();

      setState(() {
        _transactions = transactions;
        _isLoading = false;
        _calculateGoalProgress();
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  /// Calculates total income from all transactions
  double get _totalIncome => _transactions
      .where((tx) => tx.type == my_model.TransactionType.income)
      .fold(0.0, (sum, tx) => sum + tx.amount);

  /// Calculates total expenses from all transactions
  double get _totalExpense => _transactions
      .where((tx) => tx.type == my_model.TransactionType.expense)
      .fold(0.0, (sum, tx) => sum + tx.amount);

  /// Calculates current balance (income - expenses)
  double get _currentBalance => _totalIncome - _totalExpense;

  /// Formats currency amounts with the Tsh symbol
  String _formatCurrency(double amount) =>
      NumberFormat.currency(symbol: 'Tsh ', decimalDigits: 0).format(amount);

  /// Builds an empty state widget when no transactions exist
  Widget _buildEmptyState() => EmptyPage(
        pageIconData: Icons.add_box_outlined,
        pageTitle: 'No Transactions Yet',
        pageDescription: "Tap '+' to add your first transaction",
      );

  /// Shows a dialog for adding a new transaction.
  /// Handles transaction creation in Firestore.
  void _showAddTransactionDialog() {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    my_model.TransactionType type = my_model.TransactionType.expense;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => Stack(
          children: [
            AlertDialog(
              title: const Text('Add Transaction'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Transaction type dropdown
                    DropdownButtonFormField<my_model.TransactionType>(
                      value: type,
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => type = val);
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                          value: my_model.TransactionType.income,
                          child: Text('Income'),
                        ),
                        DropdownMenuItem(
                          value: my_model.TransactionType.expense,
                          child: Text('Expense'),
                        ),
                      ],
                    ),
                    // ... Rest of the dialog implementation
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Calculates and formats the remaining days until the goal deadline
  String _getRemainingDays() {
    if (_goalDeadline == null) return '';
    final now = DateTime.now();
    final difference = _goalDeadline!.difference(now).inDays;
    if (difference < 0) return 'Overdue';
    if (difference == 0) return 'Due today';
    if (difference == 1) return '1 day left';
    return '$difference days left';
  }

  @override
  Widget build(BuildContext context) {
    print('Building UI - Goal Title: $_goalTitle, Progress: $_goalProgress');
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_transactions.isEmpty
              ? _buildEmptyState()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // User profile card with financial summary
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProfilePage(user: widget.user),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF1976D2),
                              const Color(0xFF1976D2).withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1976D2).withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // User info section
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Hello, ${_displayName.isNotEmpty ? _displayName : 'User'}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (_occupation.isNotEmpty)
                                        Text(
                                          _occupation,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.8),
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              // ... Rest of the UI implementation
                            ],
                          ),
                        ),
                      ),
                    ),
                    // ... Rest of the UI implementation
                  ],
                )),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
