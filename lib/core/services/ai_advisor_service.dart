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
}