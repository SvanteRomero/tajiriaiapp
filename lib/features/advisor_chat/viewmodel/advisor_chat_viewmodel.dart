// lib/features/advisor_chat/viewmodel/advisor_chat_viewmodel.dart
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
      text: "Hello! I'm Tajiri, your financial advisor. You can ask for advice, or tell me to 'add a transaction of 5000 for lunch' or 'show my spending for this week'.",
      isFromUser: false,
    ));
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message to the list
    _messages.add(Message(text: text, isFromUser: true));
    _isLoading = true;
    notifyListeners();

    // All logic is now on the backend. Just call the main advisory function.
    try {
      final aiResponse = await _advisorService.getAdvisoryMessage(text);
      _messages.add(Message(text: aiResponse, isFromUser: false));
    } catch (e) {
      _messages.add(Message(text: "Sorry, I couldn't connect to the advisor. Please try again.", isFromUser: false));
    }

    _isLoading = false;
    notifyListeners();
  }
}