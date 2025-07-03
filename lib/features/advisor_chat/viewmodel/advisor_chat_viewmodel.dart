import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:tajiri_ai/core/models/message_model.dart';
import 'package:tajiri_ai/core/services/ai_advisor_service.dart';

class AdvisorChatViewModel extends ChangeNotifier {
  final AiAdvisorService _advisorService = AiAdvisorService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String userId;

  late final Stream<List<Message>> messagesStream;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  AdvisorChatViewModel({required this.userId}) {
    // Initialize the stream to listen for real-time chat updates from Firestore.
    messagesStream = _db
        .collection('users')
        .doc(userId)
        .collection('advisor_chats')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Message.fromFirestore(doc))
            .toList());
  }

  /// Sends a message and saves both the user's message and the AI's response to Firestore.
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _isLoading = true;
    notifyListeners();

    // Save the user's message to Firestore immediately.
    final userMessage = Message(
      text: text,
      isFromUser: true,
      timestamp: Timestamp.now(),
    );
    await _getChatCollection().add(userMessage.toJson());

    try {
      // Get the response from the AI service.
      final aiResponseText = await _advisorService.getAdvisoryMessage(text);
      
      // Save the AI's response to Firestore.
      final aiMessage = Message(
        text: aiResponseText,
        isFromUser: false,
        timestamp: Timestamp.now(),
      );
      await _getChatCollection().add(aiMessage.toJson());

    } catch (e) {
      // If there's an error, save an error message to the chat.
      final errorMessage = Message(
        text: "Sorry, I couldn't connect to the advisor. Please check your connection and try again.",
        isFromUser: false,
        timestamp: Timestamp.now(),
      );
      await _getChatCollection().add(errorMessage.toJson());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Helper to get a reference to the user's chat sub-collection.
  CollectionReference _getChatCollection() {
    return _db
        .collection('users')
        .doc(userId)
        .collection('advisor_chats');
  }
}