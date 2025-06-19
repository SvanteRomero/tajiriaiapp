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

    final aiResponse = await _advisorService.getAdvisoryMessage(text);

    _messages.add(Message(text: aiResponse, isFromUser: false));
    _isLoading = false;
    notifyListeners();
  }
}