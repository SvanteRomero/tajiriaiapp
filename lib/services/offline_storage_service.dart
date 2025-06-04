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
      // Check if already initialized
      if (_transactionsBox != null && _transactionsBox.isOpen) {
        return;
      }

      final appDocumentDir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDocumentDir.path);
      
      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(HiveTransactionAdapter());
      }

      // Open boxes with retry mechanism
      int retryCount = 0;
      while (retryCount < 3) {
        try {
          _transactionsBox = await Hive.openBox<HiveTransaction>(transactionsBoxName);
          break;
        } catch (e) {
          retryCount++;
          if (retryCount == 3) {
            throw Exception('Failed to open Hive box after 3 attempts: $e');
          }
          // Wait before retrying with exponential backoff
          await Future.delayed(Duration(seconds: 1 << retryCount));
        }
      }

      // Listen to connectivity changes and sync when online
      _connectivity.onConnectivityChanged.listen((ConnectivityResult result) async {
        if (result != ConnectivityResult.none) {
          try {
            await syncWithCloud();
          } catch (e) {
            print('Error during auto-sync: $e');
            // Store failed sync attempt for retry with context
            _pendingOperations.add(() async {
              try {
                await syncWithCloud();
              } catch (retryError) {
                print('Retry sync failed: $retryError');
                throw retryError; // Propagate error for batch processing
              }
            });
          }
        }
      });
    } catch (e) {
      print('Error initializing offline storage: $e');
      throw Exception('Failed to initialize offline storage: $e');
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

  /// Get all transactions for a user with error handling and validation
  List<HiveTransaction> getTransactions(String userId) {
    if (userId.isEmpty) {
      throw ArgumentError('userId cannot be empty');
    }

    try {
      // Ensure service is initialized
      if (_transactionsBox == null || !_transactionsBox.isOpen) {
        throw StateError('Storage service not initialized. Call initialize() first.');
      }

      // Check cache first with timestamp validation
      if (_transactionsCache.containsKey(userId)) {
        final cachedData = _transactionsCache[userId]!;
        // Return a defensive copy of cached data
        return List.from(cachedData);
      }

      // Fetch and validate transactions
      final transactions = _transactionsBox.values
          .where((tx) => tx.userId == userId)
          .map((tx) {
            // Validate transaction data
            if (tx.amount.isNaN || tx.amount.isInfinite) {
              print('Warning: Invalid amount in transaction ${tx.id}');
              return null;
            }
            if (tx.date.isAfter(DateTime.now().add(const Duration(days: 1)))) {
              print('Warning: Future date in transaction ${tx.id}');
              return null;
            }
            return tx;
          })
          .where((tx) => tx != null)
          .cast<HiveTransaction>()
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      
      // Update cache with a defensive copy
      _transactionsCache[userId] = List.from(transactions);
      
      return transactions;
    } catch (e) {
      print('Error getting transactions: $e');
      throw StateError('Failed to retrieve transactions: $e');
    }
  }

  /// Process pending operations in batch with improved error handling
  Future<void> _processPendingOperations() async {
    if (_isBatchProcessing || _pendingOperations.isEmpty) return;

    _isBatchProcessing = true;
    int retryDelay = 1000; // Start with 1 second delay
    int consecutiveFailures = 0;
    
    try {
      // Process operations in batches of 5
      while (_pendingOperations.isNotEmpty) {
        if (consecutiveFailures >= 3) {
          print('Too many consecutive failures, pausing sync operations');
          // Clear pending operations to prevent infinite retry
          _pendingOperations.clear();
          break;
        }

        final batch = _pendingOperations.take(5).toList();
        _pendingOperations.removeRange(0, batch.length);
        
        try {
          await Future.wait(
            batch.map((operation) => operation()),
            eagerError: true,
          );
          // Reset counters on success
          retryDelay = 1000;
          consecutiveFailures = 0;
        } catch (e) {
          print('Error processing batch: $e');
          consecutiveFailures++;
          
          // Add failed operations back to the queue
          _pendingOperations.addAll(batch);
          
          // Implement exponential backoff with jitter
          final jitter = (DateTime.now().millisecondsSinceEpoch % 1000) / 1000;
          final delay = retryDelay * (1 + jitter);
          await Future.delayed(Duration(milliseconds: delay.round()));
          
          retryDelay *= 2; // Double the delay for next retry
          if (retryDelay > 32000) { // Cap at 32 seconds
            retryDelay = 32000;
          }
          continue;
        }
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

  /// Sync all unsynced transactions with cloud with improved error handling
  Future<void> syncWithCloud() async {
    if (!_transactionsBox.isOpen) {
      throw StateError('Transaction box is not open');
    }

    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw StateError('No internet connection available');
      }

      final unsynced = _transactionsBox.values.where((tx) => !tx.isSynced).toList();
      if (unsynced.isEmpty) return;

      // Group transactions by user for batch processing
      final transactionsByUser = <String, List<HiveTransaction>>{};
      for (var tx in unsynced) {
        transactionsByUser.putIfAbsent(tx.userId, () => []).add(tx);
      }

      // Process each user's transactions in batch
      for (var entry in transactionsByUser.entries) {
        final userId = entry.key;
        final transactions = entry.value;

        try {
          final batch = _firestore.batch();
          for (var tx in transactions) {
            final docRef = _firestore
                .collection('users')
                .doc(userId)
                .collection('transactions')
                .doc(tx.id);
            batch.set(docRef, tx.toJson());
          }
          await batch.commit();

          // Mark transactions as synced
          for (var tx in transactions) {
            tx.isSynced = true;
            await tx.save();
          }
        } catch (e) {
          print('Error syncing batch for user $userId: $e');
          // Add failed batch to pending operations
          _pendingOperations.add(() => syncWithCloud());
          rethrow;
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
