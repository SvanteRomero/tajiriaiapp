import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:tajiri_ai/pages/profile_page.dart';
import '../models/transaction.dart' as my_model;
import '../models/hive/transaction_model.dart';
import '../services/offline_storage_service.dart';
import '../widgets/profile_card.dart';
import '../widgets/transaction_item.dart';
import '../widgets/goal_progress.dart';
import 'package:tajiri_ai/components/empty_page.dart';

/// HomeContent is the main dashboard screen of the application
/// Displays user's financial overview, current goals, and recent transactions
class HomeContent extends StatefulWidget {
  /// Currently authenticated user
  final User user;
  
  const HomeContent({Key? key, required this.user}) : super(key: key);

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  bool _isLoading = true;
  bool _isFetching = false;
  List<my_model.Transaction> _transactions = [];
  
  // Memoized values using ValueNotifier
  final ValueNotifier<String> _displayNameNotifier = ValueNotifier('');
  final ValueNotifier<String> _occupationNotifier = ValueNotifier('');
  final ValueNotifier<double> _totalIncomeNotifier = ValueNotifier(0.0);
  final ValueNotifier<double> _totalExpenseNotifier = ValueNotifier(0.0);
  final ValueNotifier<double> _currentBalanceNotifier = ValueNotifier(0.0);
  final ValueNotifier<double> _goalProgressNotifier = ValueNotifier(0.0);

  // Goal information
  String _goalTitle = '';
  int _goalTarget = 0;
  DateTime? _goalDeadline;
  String? _currentGoalId;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _displayNameNotifier.dispose();
    _occupationNotifier.dispose();
    _totalIncomeNotifier.dispose();
    _totalExpenseNotifier.dispose();
    _currentBalanceNotifier.dispose();
    _goalProgressNotifier.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    if (_isFetching) return;
    
    setState(() {
      _isFetching = true;
      _isLoading = true;
    });

    try {
      await Future.wait([
        _fetchUserInfo(),
        _fetchTransactions(),
        _fetchCurrentGoal(),
      ]);
    } catch (e) {
      print('Error initializing data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _initializeData,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetching = false;
          _isLoading = false;
        });
      }
    }
  }

  // Update financial metrics in the background
  Future<void> _updateFinancialMetrics() async {
    final metrics = await compute<List<my_model.Transaction>, Map<String, double>>(
      (transactions) {
        double income = 0.0;
        double expense = 0.0;
        
        for (var tx in transactions) {
          if (tx.type == my_model.TransactionType.income) {
            income += tx.amount;
          } else {
            expense += tx.amount;
          }
        }
        
        return {
          'income': income,
          'expense': expense,
          'balance': income - expense,
        };
      },
      _transactions,
    );

    if (!mounted) return;
    
    _totalIncomeNotifier.value = metrics['income']!;
    _totalExpenseNotifier.value = metrics['expense']!;
    _currentBalanceNotifier.value = metrics['balance']!;
  }

  Future<void> _fetchUserInfo() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get();
      
      if (doc.exists && mounted) {
        final data = doc.data();
        if (data != null) {
          _displayNameNotifier.value = data['name'] ?? '';
          _occupationNotifier.value = data['occupation'] ?? '';
        }
      }
    } catch (e) {
      print('Error fetching user info: $e');
    }
  }

  Future<void> _fetchTransactions() async {
    if (!mounted) return;
    
    try {
      final offlineStorage = Provider.of<OfflineStorageService>(context, listen: false);
      
      // Get transactions from local storage
      final localTransactions = offlineStorage.getTransactions(widget.user.uid);
      
      // Convert Hive transactions to app model
      final transactions = localTransactions.map((tx) => my_model.Transaction(
        username: tx.username,
        description: tx.description,
        amount: tx.amount,
        date: tx.date,
        type: tx.type == 'income' 
            ? my_model.TransactionType.income 
            : my_model.TransactionType.expense,
      )).toList();

      if (mounted) {
        setState(() => _transactions = transactions);
        await _updateFinancialMetrics();
        _calculateGoalProgress();
      }

      // Background sync
      if (!_isFetching) {
        unawaited(_performBackgroundSync(offlineStorage));
      }
    } catch (e) {
      print('Error fetching transactions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading transactions: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _fetchTransactions,
            ),
          ),
        );
      }
    }
  }

  Future<void> _performBackgroundSync(OfflineStorageService offlineStorage) async {
    try {
      await Future.wait([
        offlineStorage.downloadFromCloud(widget.user.uid),
        offlineStorage.syncWithCloud(),
      ]);

      if (!mounted) return;

      final updatedTransactions = offlineStorage.getTransactions(widget.user.uid);
      setState(() {
        _transactions = updatedTransactions.map((tx) => my_model.Transaction(
          username: tx.username,
          description: tx.description,
          amount: tx.amount,
          date: tx.date,
          type: tx.type == 'income' 
              ? my_model.TransactionType.income 
              : my_model.TransactionType.expense,
        )).toList();
      });
      
      await _updateFinancialMetrics();
      _calculateGoalProgress();
    } catch (e) {
      print('Background sync error: $e');
    }
  }

  void _calculateGoalProgress() {
    if (_goalTarget <= 0) {
      _goalProgressNotifier.value = 0;
      return;
    }

    final totalSavings = _currentBalanceNotifier.value;
    _goalProgressNotifier.value = (totalSavings / _goalTarget).clamp(0, 1);

    if (_goalProgressNotifier.value >= 1.0) {
      _showGoalAchievedDialog();
    }
  }

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
                          _goalProgressNotifier.value = 0;
                          _currentGoalId = null;
                        });
                      }
                      if (mounted) Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
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
                    ),
                    child: const Text('Set New Goal'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddNewGoalDialog() async {
    final titleController = TextEditingController(text: _goalTitle);
    final amountController = TextEditingController(
      text: _goalTarget > 0 ? _goalTarget.toString() : '',
    );
    DateTime selectedDeadline = _goalDeadline ?? DateTime.now().add(const Duration(days: 30));

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                  lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
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
            onPressed: () => _saveGoal(
              titleController.text,
              amountController.text,
              selectedDeadline,
            ),
            child: Text(_goalTitle.isEmpty ? 'Set Goal' : 'Update Goal'),
          ),
        ],
      ),
    );

    titleController.dispose();
    amountController.dispose();
  }

  Future<void> _saveGoal(String title, String amount, DateTime deadline) async {
    if (title.isEmpty || amount.isEmpty) return;

    try {
      final goal = {
        'title': title.trim(),
        'target': int.parse(amount.trim()),
        'deadline': deadline.toIso8601String(),
        'status': 'active',
        'userId': widget.user.uid,
        'createdAt': DateTime.now().toIso8601String(),
      };

      if (_currentGoalId != null) {
        await FirebaseFirestore.instance
            .collection('goals')
            .doc(_currentGoalId)
            .update(goal);
      } else {
        await FirebaseFirestore.instance
            .collection('goals')
            .add(goal);
      }

      if (mounted) {
        Navigator.pop(context);
        await _fetchCurrentGoal();
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
      if (mounted) {
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
  }

  Future<void> _showAddTransactionDialog() async {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    my_model.TransactionType type = my_model.TransactionType.expense;
    bool isSubmitting = false;

    await showDialog(
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
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Amount'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Date: ${DateFormat.yMMMd().format(selectedDate)}'),
                        TextButton(
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (pickedDate != null) {
                              setDialogState(() => selectedDate = pickedDate);
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
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : () async {
                    final description = descriptionController.text.trim();
                    final amount = double.tryParse(amountController.text.trim()) ?? 0;
                    if (description.isEmpty || amount <= 0) return;

                    setDialogState(() => isSubmitting = true);

                    try {
                      final offlineStorage = Provider.of<OfflineStorageService>(
                        context, 
                        listen: false
                      );

                      final transactionId = DateTime.now().millisecondsSinceEpoch.toString();
                      
                      await offlineStorage.addTransaction(
                        HiveTransaction(
                          id: transactionId,
                          username: _displayNameNotifier.value,
                          description: description,
                          amount: amount,
                          date: selectedDate,
                          type: type == my_model.TransactionType.income ? 'income' : 'expense',
                          userId: widget.user.uid,
                        ),
                      );

                      if (context.mounted) {
                        Navigator.pop(context);
                        await _fetchTransactions();
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error adding transaction: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        setDialogState(() => isSubmitting = false);
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
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    descriptionController.dispose();
    amountController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionDialog(),
        child: const Icon(Icons.add),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_transactions.isEmpty
              ? const EmptyPage(
                  pageIconData: Icons.add_box_outlined,
                  pageTitle: 'No Transactions Yet',
                  pageDescription: "Tap '+' to add your first transaction",
                )
              : RefreshIndicator(
                  onRefresh: _initializeData,
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            // Profile Card
                            ValueListenableBuilder<String>(
                              valueListenable: _displayNameNotifier,
                              builder: (context, displayName, _) => 
                                ValueListenableBuilder<String>(
                                  valueListenable: _occupationNotifier,
                                  builder: (context, occupation, _) =>
                                    ValueListenableBuilder<double>(
                                      valueListenable: _currentBalanceNotifier,
                                      builder: (context, balance, _) => ProfileCard(
                                        displayName: displayName,
                                        occupation: occupation,
                                        balance: balance,
                                        onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => ProfilePage(user: widget.user),
                                          ),
                                        ),
                                        formatCurrency: _formatCurrency,
                                      ),
                                    ),
                                ),
                            ),
                            const SizedBox(height: 24),

                            // Goal Progress
                            if (_goalTitle.isNotEmpty)
                              ValueListenableBuilder<double>(
                                valueListenable: _goalProgressNotifier,
                                builder: (context, progress, _) => GoalProgress(
                                  title: _goalTitle,
                                  progress: progress,
                                  target: _goalTarget.toDouble(),
                                  remainingDays: _getRemainingDays(),
                                  formatCurrency: _formatCurrency,
                                  onEditPressed: _showAddNewGoalDialog,
                                  onBudgetPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Budget feature coming soon!'),
                                        backgroundColor: Color(0xFF1976D2),
                                      ),
                                    );
                                  },
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
                          ]),
                        ),
                      ),

                      // Transaction List
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final transaction = _transactions[index];
                              return TransactionItem(
                                transaction: transaction,
                                formatCurrency: _formatCurrency,
                                onDelete: () async {
                                  try {
                                    final offlineStorage = Provider.of<OfflineStorageService>(
                                      context,
                                      listen: false
                                    );
                                    
                                    final transactionId = transaction.date.millisecondsSinceEpoch.toString() + 
                                                        transaction.description;
                                    
                                    await offlineStorage.deleteTransaction(
                                      transactionId,
                                      widget.user.uid,
                                    );
                                    return true;
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error deleting transaction: ${e.toString()}'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                    return false;
                                  }
                                },
                                onDismissed: () {
                                  setState(() => _transactions.removeAt(index));
                                  _updateFinancialMetrics();
                                  _calculateGoalProgress();
                                },
                              );
                            },
                            childCount: _transactions.length,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  String _formatCurrency(double amount) =>
      NumberFormat.currency(symbol: 'Tsh ', decimalDigits: 0).format(amount);

  String _getRemainingDays() {
    if (_goalDeadline == null) return '';
    final now = DateTime.now();
    final difference = _goalDeadline!.difference(now).inDays;
    if (difference < 0) return 'Overdue';
    if (difference == 0) return 'Due today';
    if (difference == 1) return '1 day left';
    return '$difference days left';
  }
}
