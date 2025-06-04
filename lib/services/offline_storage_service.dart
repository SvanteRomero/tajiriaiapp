import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/hive/transaction_model.dart';

class OfflineStorageService {
  static const String transactionsBoxName = 'transactions';
  late Box<HiveTransaction> _transactionsBox;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();

  /// Initialize Hive and open boxes
  Future<void> initialize() async {
    try {
      final appDocumentDir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDocumentDir.path);
      
      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(HiveTransactionAdapter());
      }

      // Open boxes
      _transactionsBox = await Hive.openBox<HiveTransaction>(transactionsBoxName);

      // Listen to connectivity changes and sync when online
      _connectivity.onConnectivityChanged.listen((ConnectivityResult result) async {
        if (result != ConnectivityResult.none) {
          try {
            await syncWithCloud();
          } catch (e) {
            print('Error during auto-sync: $e');
          }
        }
      });
    } catch (e) {
      print('Error initializing offline storage: $e');
      // Ensure the error is propagated
      rethrow;
    }
  }

  /// Add a transaction locally
  Future<void> addTransaction(HiveTransaction transaction) async {
    try {
      await _transactionsBox.put(transaction.id, transaction);
      
      // Try to sync immediately if online
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        await _syncTransaction(transaction);
      }
    } catch (e) {
      print('Error adding transaction: $e');
      rethrow;
    }
  }

  /// Get all transactions for a user
  List<HiveTransaction> getTransactions(String userId) {
    try {
      final transactions = _transactionsBox.values
          .where((tx) => tx.userId == userId)
          .toList();
      
      // Sort by date descending
      transactions.sort((a, b) => b.date.compareTo(a.date));
      
      return transactions;
    } catch (e) {
      print('Error getting transactions: $e');
      return [];
    }
  }

  /// Delete a transaction both locally and from cloud
  Future<void> deleteTransaction(String transactionId, String userId) async {
    try {
      // Delete from local storage
      await _transactionsBox.delete(transactionId);

      // Try to delete from cloud if online
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('transactions')
              .doc(transactionId)
              .delete();
        } catch (e) {
          print('Error deleting from cloud: $e');
          // Continue as the local delete was successful
        }
      }
    } catch (e) {
      print('Error deleting transaction: $e');
      rethrow;
    }
  }

  /// Sync a single transaction with Firestore
  Future<void> _syncTransaction(HiveTransaction transaction) async {
    if (transaction.isSynced) return;

    try {
      await _firestore
          .collection('users')
          .doc(transaction.userId)
          .collection('transactions')
          .doc(transaction.id)
          .set(transaction.toJson());

      transaction.isSynced = true;
      await transaction.save();
    } catch (e) {
      print('Error syncing transaction: $e');
    }
  }

  /// Sync all unsynced transactions with cloud
  Future<void> syncWithCloud() async {
    try {
      final unsynced = _transactionsBox.values.where((tx) => !tx.isSynced).toList();
      
      for (var transaction in unsynced) {
        try {
          await _syncTransaction(transaction);
        } catch (e) {
          print('Error syncing transaction ${transaction.id}: $e');
          // Continue with next transaction even if one fails
          continue;
        }
      }
    } catch (e) {
      print('Error during sync: $e');
      rethrow;
    }
  }

  /// Download transactions from cloud
  Future<void> downloadFromCloud(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .get();

      for (var doc in snapshot.docs) {
        final transaction = HiveTransaction.fromFirestore(
          doc.data(),
          doc.id,
          userId,
        );
        await _transactionsBox.put(transaction.id, transaction);
      }
    } catch (e) {
      print('Error downloading transactions: $e');
    }
  }

  /// Clear all stored transactions
  Future<void> clearStorage() async {
    await _transactionsBox.clear();
  }

  /// Close Hive boxes
  Future<void> dispose() async {
    await _transactionsBox.close();
  }
}
