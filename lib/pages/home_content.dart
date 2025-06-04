import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/transaction_form.dart';
import '../widgets/transaction_item.dart';
import '../models/hive/transaction_model.dart';
import '../services/offline_storage_service.dart';

class HomeContent extends StatefulWidget {
  final User user;
  final String username;

  const HomeContent({
    Key? key,
    required this.user,
    required this.username,
  }) : super(key: key);

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final _offlineStorage = OfflineStorageService();

  void _handleNewTransaction(HiveTransaction transaction) async {
    // Save to local storage first
    await _offlineStorage.addTransaction(transaction);

    // Then try to sync with Firestore
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .collection('transactions')
          .doc(transaction.id)
          .set(transaction.toJson());

      // Mark as synced in local storage
      transaction.isSynced = true;
      await transaction.save();
    } catch (e) {
      // Transaction will remain marked as not synced
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction saved locally. Will sync when online.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Transaction Form
        Padding(
          padding: const EdgeInsets.all(16),
          child: TransactionForm(
            onSubmit: _handleNewTransaction,
            userId: widget.user.uid,
            username: widget.username,
          ),
        ),

        // Transactions List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(widget.user.uid)
                .collection('transactions')
                .orderBy('date', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    'No transactions yet',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                );
              }

              final transactions = snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return HiveTransaction.fromFirestore(data, doc.id, widget.user.uid);
              }).toList();

              return ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  return TransactionItem(
                    transaction: transactions[index],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
