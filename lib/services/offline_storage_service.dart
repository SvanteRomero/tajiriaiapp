import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../models/hive/transaction_model.dart';

class OfflineStorageService {
  static const String transactionsBoxName = 'transactions';
  late Box<HiveTransaction> _transactionsBox;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();
  
  // Cache for transactions to avoid frequent box reads
  Map<String, List<HiveTransaction>> _transactionsCache = {};
  
  // Batch operation queue
  final List<Future Function()> _pendingOperations = [];
  bool _isBatchProcessing = false;

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
      // Update local storage
      await _transactionsBox.put(transaction.id, transaction);
      
      // Clear cache
      _clearCache(transaction.userId);
      
      // Queue cloud sync
      _pendingOperations.add(() async {
        final connectivityResult = await _connectivity.checkConnectivity();
        if (connectivityResult != ConnectivityResult.none) {
          await _syncTransaction(transaction);
        }
      });

      // Process pending operations
      unawaited(_processPendingOperations());
    } catch (e) {
      print('Error adding transaction: $e');
      rethrow;
    }
  }

  /// Get all transactions for a user
  List<HiveTransaction> getTransactions(String userId) {
    try {
      // Check cache first
      if (_transactionsCache.containsKey(userId)) {
        return _transactionsCache[userId]!;
      }

      final transactions = _transactionsBox.values
          .where((tx) => tx.userId == userId)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      
      // Update cache
      _transactionsCache[userId] = transactions;
      
      return transactions;
    } catch (e) {
      print('Error getting transactions: $e');
      return [];
    }
  }

  /// Process pending operations in batch
  Future<void> _processPendingOperations() async {
    if (_isBatchProcessing || _pendingOperations.isEmpty) return;

    _isBatchProcessing = true;
    try {
      // Process operations in batches of 5
      while (_pendingOperations.isNotEmpty) {
        final batch = _pendingOperations.take(5).toList();
        _pendingOperations.removeRange(0, batch.length);
        
        await Future.wait(
          batch.map((operation) => operation()),
          eagerError: false,
        );
      }
    } finally {
      _isBatchProcessing = false;
    }
  }

  /// Clear cache for a user
  void _clearCache(String userId) {
    _transactionsCache.remove(userId);
  }

  /// Delete a transaction both locally and from cloud
  Future<void> deleteTransaction(String transactionId, String userId) async {
    try {
      // Delete from local storage
      await _transactionsBox.delete(transactionId);
      
      // Clear cache
      _clearCache(userId);

      // Queue cloud delete
      _pendingOperations.add(() async {
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
          }
        }
      });

      // Process pending operations
      unawaited(_processPendingOperations());
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
