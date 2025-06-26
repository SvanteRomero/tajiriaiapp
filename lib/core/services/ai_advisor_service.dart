import 'package:cloud_functions/cloud_functions.dart';

class AiAdvisorService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<String> getAdvisoryMessage(String userMessage) async {
    try {
      final callable = _functions.httpsCallable('getAdvisoryMessage');
      final response = await callable.call<Map<String, dynamic>>({'message': userMessage});
      return response.data['reply'] as String;
    } on FirebaseFunctionsException catch (e) {
      print('Firebase Functions Error: ${e.code} - ${e.message}');
      return 'Sorry, an error occurred on our end. Please try again later.';
    } catch (e) {
      print('Generic Error: $e');
      return 'An unexpected error occurred. Please check your connection.';
    }
  }

  Future<String> suggestDailyLimit() async {
    try {
      final callable = _functions.httpsCallable('suggestDailyLimit');
      final response = await callable.call<Map<String, dynamic>>({});
      return response.data['reply'] as String;
    } on FirebaseFunctionsException catch (e) {
      print('Firebase Functions Error: ${e.code} - ${e.message}');
      return 'Could not get a suggestion at this time.';
    } catch (e) {
      print('Generic Error: $e');
      return 'An unexpected error occurred while getting suggestion.';
    }
  }

  Future<String> createTransaction(Map<String, dynamic> transactionData) async {
    try {
      final callable = _functions.httpsCallable('createTransaction');
      final response = await callable.call<Map<String, dynamic>>(transactionData);
      return response.data['message'] as String;
    } on FirebaseFunctionsException catch (e) {
      return e.message ?? 'Failed to create transaction.';
    }
  }

  Future<String> getSpendingSummary(String timeFrame) async {
    try {
      final callable = _functions.httpsCallable('getSpendingSummary');
      final response = await callable.call<Map<String, dynamic>>({'timeFrame': timeFrame});
      return response.data['reply'] as String;
    } on FirebaseFunctionsException catch (e) {
      return e.message ?? 'Could not get summary.';
    }
  }

  Future<String> createGoal(Map<String, dynamic> goalData) async {
    try {
      final callable = _functions.httpsCallable('createGoal');
      final response = await callable.call<Map<String, dynamic>>(goalData);
      return response.data['message'] as String;
    } on FirebaseFunctionsException catch (e) {
      return e.message ?? 'Failed to create goal.';
    }
  }

  Future<String> createBudget(Map<String, dynamic> budgetData) async {
    try {
      final callable = _functions.httpsCallable('createBudget');
      final response = await callable.call<Map<String, dynamic>>(budgetData);
      return response.data['message'] as String;
    } on FirebaseFunctionsException catch (e) {
      return e.message ?? 'Failed to create budget.';
    }
  }

  Future<String> deleteTransaction(String transactionId) async {
    try {
      final callable = _functions.httpsCallable('deleteTransaction');
      await callable.call({'transactionId': transactionId});
      return 'Transaction deleted successfully.';
    } on FirebaseFunctionsException catch (e) {
      return e.message ?? 'Failed to delete transaction.';
    }
  }
}