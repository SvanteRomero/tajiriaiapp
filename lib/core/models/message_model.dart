import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String text;
  final bool isFromUser;
  final Timestamp timestamp; // For ordering messages

  Message({
    required this.text,
    required this.isFromUser,
    required this.timestamp,
  });

  /// Creates a Message object from a Firestore document.
  factory Message.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Message(
      text: data['text'] ?? '',
      isFromUser: data['isFromUser'] ?? false,
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  /// Converts a Message object to a JSON map for Firestore.
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isFromUser': isFromUser,
      'timestamp': timestamp,
    };
  }
}