import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:tajiri_ai/pages/profile_page.dart';
import '../models/transaction.dart' as my_model;
import 'package:tajiri_ai/components/empty_page.dart';

class Home extends StatefulWidget {
  final User user;
  const Home({Key? key, required this.user}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool _isLoading = true;
  List<my_model.Transaction> _transactions = [];
  String _displayName = '';
  String _occupation = '';
  int _age = 0;
  String _goalTitle = '';
  int _goalTarget = 0;
  DateTime? _goalDeadline;
  double _goalProgress = 0;
  String? _currentGoalId;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
    _fetchTransactions();
    _fetchCurrentGoal();
  }

  Future<void> _fetchUserInfo() async {
    try {
      final doc =
          await FirebaseFirestore.instance
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
    } catch (_) {}
  }

  Future<void> _fetchCurrentGoal() async {
    try {
      print('Fetching goals for user: ${widget.user.uid}');
      final snapshot =
          await FirebaseFirestore.instance
              .collection('goals')
              .where('userId', isEqualTo: widget.user.uid)
              .where('status', isEqualTo: 'active')
              .get();

      print('Found ${snapshot.docs.length} active goals');

      if (snapshot.docs.isNotEmpty) {
        // Sort the results in memory instead of in the query
        final sortedDocs =
            snapshot.docs.toList()..sort((a, b) {
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

  void _calculateGoalProgress() {
    print('Calculating progress for goal: $_goalTitle');
    print('Current target: $_goalTarget');

    if (_goalTarget <= 0) {
      setState(() {
        _goalProgress = 0;
      });
      return;
    }

    // Calculate total savings (income - expenses)
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

    // Calculate progress as a percentage of the goal target
    double newProgress = (totalSavings / _goalTarget).clamp(0, 1);
    print('Calculated progress: $newProgress');

    setState(() {
      _goalProgress = newProgress;
    });

    // Check if goal is achieved
    if (newProgress >= 1.0) {
      _showGoalAchievedDialog();
    }
  }

  void _showGoalAchievedDialog() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
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
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatCurrency(_goalTarget.toDouble()),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Target Amount Achieved!',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () async {
                          if (_currentGoalId != null) {
                            await FirebaseFirestore.instance
                                .collection('goals')
                                .doc(_currentGoalId)
                                .update({'status': 'completed'});
                            setState(() {
                              _goalTitle = '';
                              _goalTarget = 0;
                              _goalDeadline = null;
                              _goalProgress = 0;
                              _currentGoalId = null;
                            });
                          }
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Continue'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showAddNewGoalDialog();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1976D2),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Set New Goal',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showAddNewGoalDialog() {
    final titleController = TextEditingController(text: _goalTitle);
    final amountController = TextEditingController(
      text: _goalTarget > 0 ? _goalTarget.toString() : '',
    );
    DateTime selectedDeadline =
        _goalDeadline ?? DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(_goalTitle.isEmpty ? 'Set New Goal' : 'Edit Goal'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                const SizedBox(height: 16),
                ListTile(
                  title: Text(
                    'Deadline: ${DateFormat.yMMMd().format(selectedDeadline)}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDeadline,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(
                        const Duration(days: 365 * 2),
                      ),
                    );
                    if (picked != null) {
                      selectedDeadline = picked;
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isEmpty ||
                      amountController.text.isEmpty) {
                    return;
                  }

                  try {
                    final goal = {
                      'title': titleController.text.trim(),
                      'target': int.parse(amountController.text.trim()),
                      'deadline': selectedDeadline.toIso8601String(),
                      'status': 'active',
                      'userId': widget.user.uid,
                      'createdAt': DateTime.now().toIso8601String(),
                    };

                    if (_currentGoalId != null) {
                      // Update existing goal
                      await FirebaseFirestore.instance
                          .collection('goals')
                          .doc(_currentGoalId)
                          .update(goal);
                    } else {
                      // Create new goal
                      await FirebaseFirestore.instance
                          .collection('goals')
                          .add(goal);
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      await _fetchCurrentGoal(); // Fetch the updated goal
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _currentGoalId != null
                                ? 'Goal updated successfully!'
                                : 'New goal set successfully!',
                          ),
                          backgroundColor: const Color(0xFF1976D2),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error ${_currentGoalId != null ? 'updating' : 'setting'} goal: ${e.toString()}',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  _currentGoalId != null ? 'Update Goal' : 'Set Goal',
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _fetchTransactions() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.user.uid)
              .collection('transactions')
              .orderBy('date', descending: true)
              .get();

      final transactions =
          snapshot.docs.map((doc) {
            final data = doc.data();
            final type =
                (data['type'] as String) == 'income'
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

  double get _totalIncome => _transactions
      .where((tx) => tx.type == my_model.TransactionType.income)
      .fold(0.0, (sum, tx) => sum + tx.amount);

  double get _totalExpense => _transactions
      .where((tx) => tx.type == my_model.TransactionType.expense)
      .fold(0.0, (sum, tx) => sum + tx.amount);

  double get _currentBalance => _totalIncome - _totalExpense;

  String _formatCurrency(double amount) =>
      NumberFormat.currency(symbol: 'Tsh ', decimalDigits: 0).format(amount);

  Widget _buildEmptyState() => EmptyPage(
    pageIconData: Icons.add_box_outlined,
    pageTitle: 'No Transactions Yet',
    pageDescription: "Tap '+' to add your first transaction",
  );

  void _showAddTransactionDialog() {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    my_model.TransactionType type = my_model.TransactionType.expense;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setDialogState) => Stack(
                  children: [
                    AlertDialog(
                      title: const Text('Add Transaction'),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
                            TextField(
                              controller: descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                              ),
                            ),
                            TextField(
                              controller: amountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Amount',
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Date: ${DateFormat.yMMMd().format(selectedDate)}',
                                ),
                                TextButton(
                                  onPressed: () async {
                                    final pickedDate = await showDatePicker(
                                      context: context,
                                      initialDate: selectedDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now(),
                                    );
                                    if (pickedDate != null) {
                                      setDialogState(
                                        () => selectedDate = pickedDate,
                                      );
                                    }
                                  },
                                  child: const Text('Pick Date'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed:
                              isSubmitting
                                  ? null
                                  : () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed:
                              isSubmitting
                                  ? null
                                  : () async {
                                    final description =
                                        descriptionController.text.trim();
                                    final amount =
                                        double.tryParse(
                                          amountController.text.trim(),
                                        ) ??
                                        0;
                                    if (description.isEmpty || amount <= 0)
                                      return;

                                    setDialogState(() => isSubmitting = true);

                                    final transaction = {
                                      'username': _displayName,
                                      'description': description,
                                      'amount': amount,
                                      'date': Timestamp.fromDate(selectedDate),
                                      'type':
                                          type ==
                                                  my_model
                                                      .TransactionType
                                                      .income
                                              ? 'income'
                                              : 'expense',
                                    };

                                    try {
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(widget.user.uid)
                                          .collection('transactions')
                                          .add(transaction);

                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        await _fetchTransactions();
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Error adding transaction: ${e.toString()}',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        setDialogState(
                                          () => isSubmitting = false,
                                        );
                                      }
                                    }
                                  },
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                    if (isSubmitting)
                      Container(
                        color: Colors.black54,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 500),
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.translate(
                                      offset: Offset(0, 20 * (1 - value)),
                                      child: const Text(
                                        'Adding Transaction...',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
          ),
    );
  }

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
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : (_transactions.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
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
                                // Top Row: User Info and Profile
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                              color: Colors.white.withOpacity(
                                                0.8,
                                              ),
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Balance Section
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Current Balance',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatCurrency(_currentBalance),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Goal Info Row
                                if (_goalTitle.isNotEmpty)
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _goalTitle,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          '${(_goalProgress * 100).toStringAsFixed(1)}%',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                if (_goalTitle.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  // Progress Bar
                                  Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(2),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(2),
                                      child: LinearProgressIndicator(
                                        value: _goalProgress,
                                        backgroundColor: Colors.white
                                            .withOpacity(0.15),
                                        color:
                                            _goalProgress >= 1.0
                                                ? const Color(
                                                  0xFF64B5F6,
                                                ) // Lighter blue for completed
                                                : const Color(
                                                  0xFF90CAF9,
                                                ), // Even lighter blue for in progress
                                        minHeight: 4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // Goal Details
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Target: ${_formatCurrency(_goalTarget.toDouble())}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                      Text(
                                        _getRemainingDays(),
                                        style: TextStyle(
                                          color:
                                              _goalDeadline?.isBefore(
                                                        DateTime.now(),
                                                      ) ??
                                                      false
                                                  ? Colors.red[300]
                                                  : Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 12),

                                // Action Buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed:
                                            () => _showAddNewGoalDialog(),
                                        icon: Icon(
                                          _goalTitle.isEmpty
                                              ? Icons.add
                                              : Icons.edit,
                                          size: 16,
                                        ),
                                        label: Text(
                                          _goalTitle.isEmpty
                                              ? 'Add Goal'
                                              : 'Edit Goal',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white
                                              .withOpacity(0.2),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Budget feature coming soon!',
                                              ),
                                              backgroundColor: Color(
                                                0xFF1976D2,
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.account_balance,
                                          size: 16,
                                        ),
                                        label: const Text(
                                          'Add Budget',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white
                                              .withOpacity(0.2),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._transactions.map(
                        (tx) => ListTile(
                          leading: Icon(
                            tx.type == my_model.TransactionType.income
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color:
                                tx.type == my_model.TransactionType.income
                                    ? Colors.green
                                    : Colors.red,
                          ),
                          title: Text(tx.description),
                          subtitle: Text(DateFormat.yMMMd().format(tx.date)),
                          trailing: Text(
                            '${tx.type == my_model.TransactionType.income ? '+' : '-'} ${_formatCurrency(tx.amount)}',
                            style: TextStyle(
                              color:
                                  tx.type == my_model.TransactionType.income
                                      ? Colors.green
                                      : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
