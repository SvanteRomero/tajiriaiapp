import 'package:flutter/foundation.dart';
import '../../../core/models/message_model.dart';
import '../../../core/services/ai_advisor_service.dart';

class AdvisorChatViewModel extends ChangeNotifier {
  final AiAdvisorService _advisorService = AiAdvisorService();

  final List<Message> _messages = [];
  bool _isLoading = false;

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;

  AdvisorChatViewModel() {
    _messages.add(Message(
      text: "Hello! I'm Tajiri, your financial advisor. Feel free to ask about your spending, for saving tips, or for a summary of your expenses.",
      isFromUser: false,
    ));
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _messages.add(Message(text: text, isFromUser: true));
    _isLoading = true;
    notifyListeners();

    // Intent Parsing
    if (text.toLowerCase().contains('add transaction') || text.toLowerCase().contains('i spent')) {
      // Basic entity extraction (can be improved with a more robust NLP solution)
      final parts = text.split(' ');
      final amount = double.tryParse(parts.firstWhere((p) => p.startsWith('\$'), orElse: () => '0').substring(1));
      final description = text.substring(text.indexOf('on') + 3);

      if (amount != null && amount > 0) {
        final response = await _advisorService.createTransaction({
          'description': description,
          'amount': amount,
          'type': 'expense',
          'category': 'Uncategorized', // Default category
          'accountId': 'default_account' // Default account
        });
        _messages.add(Message(text: response, isFromUser: false));
      } else {
        _messages.add(Message(text: "I couldn't understand the amount. Please try again.", isFromUser: false));
      }
    } else if (text.toLowerCase().contains('show spending')) {
      final timeFrame = _extractTimeFrame(text);
      final summary = await _advisorService.getSpendingSummary(timeFrame);
      _messages.add(Message(text: summary, isFromUser: false));
    } else if (text.toLowerCase().contains('create goal')) {
       _messages.add(Message(text: "What is the name of your goal?", isFromUser: false));
       // In a real app, you would manage a conversation flow here
    } else if (text.toLowerCase().contains('create budget')) {
      _messages.add(Message(text: "What category is this budget for?", isFromUser: false));
      // Conversation flow management
    } else if (text.toLowerCase().contains('delete last transaction')) {
      // This requires getting the last transaction's ID, which is not implemented here for simplicity
      _messages.add(Message(text: "This feature is not fully implemented yet.", isFromUser: false));
    }
    else {
      final aiResponse = await _advisorService.getAdvisoryMessage(text);
      _messages.add(Message(text: aiResponse, isFromUser: false));
    }

    _isLoading = false;
    notifyListeners();
  }

  String _extractTimeFrame(String text) {
    if (text.contains('this month')) {
      return 'this month';
    }
    if (text.contains('last month')) {
      return 'last month';
    }
    if (text.contains('this week')) {
      return 'this week';
    }
    if (text.contains('last week')) {
      return 'last week';
    }
    if (text.contains('today')) {
      return 'today';
    }
    if (text.contains('yesterday')) {
      return 'yesterday';
    }
    return 'all time';
  }
}