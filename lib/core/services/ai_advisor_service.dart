// lib/core/services/ai_advisor_service.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AiAdvisorService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<bool> _isConnected() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    return !connectivityResult.contains(ConnectivityResult.none);
  }

  Future<String> getAdvisoryMessage(String userMessage) async {
    if (!await _isConnected()) {
      return "You seem to be offline. Please check your internet connection to chat with Tajiri.";
    }
    try {
      // This is now the single point of contact for the AI advisor.
      final callable = _functions.httpsCallable('getAdvisoryMessage');
      final response = await callable.call<Map<String, dynamic>>({'message': userMessage});
      return response.data['reply'] as String;
    } on FirebaseFunctionsException catch (e) {
      print('Firebase Functions Error: ${e.code} - ${e.message}');
      if (e.code == 'unavailable') {
        return 'Could not reach our servers. Please check your connection and try again.';
      }
      return 'Sorry, an error occurred on our end. Please try again later.';
    } catch (e) {
      print('Generic Error: $e');
      return 'An unexpected error occurred. Please check your connection.';
    }
  }

  Future<String> suggestDailyLimit() async {
    if (!await _isConnected()) {
      throw Exception("No internet connection. Cannot get suggestion.");
    }
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
}