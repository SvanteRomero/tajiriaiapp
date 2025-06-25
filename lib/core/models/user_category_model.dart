// lib/core/models/user_category_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // Needed for Color and IconData conversion helpers
import 'package:tajiri_ai/core/models/transaction_model.dart'; // For TransactionType

class UserCategory {
  final String? id; // Null for new categories before saving to Firestore
  final String name;
  final TransactionType type; // expense or income
  final String? colorHex; // Optional: stored as hex string (e.g., "FF0000" for red)
  final String? iconCodePoint; // Optional: stored as string representation of icon's codePoint (e.g., "0xe06e" for Icons.category.codePoint)

  UserCategory({
    this.id,
    required this.name,
    required this.type,
    this.colorHex,
    this.iconCodePoint,
  });

  factory UserCategory.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return UserCategory(
      id: doc.id,
      name: data['name'] ?? '',
      type: (data['type'] == 'income') ? TransactionType.income : TransactionType.expense,
      colorHex: data['colorHex'],
      iconCodePoint: data['iconCodePoint'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type.name, // 'income' or 'expense'
      'colorHex': colorHex,
      'iconCodePoint': iconCodePoint,
    };
  }

  // Helper to convert hex string to Color object
  Color get color {
    if (colorHex == null || colorHex!.isEmpty) return Colors.grey; // Default color
    try {
      // Add 'ff' for full opacity if not already present, then parse
      String cleanHex = colorHex!.startsWith('0x') ? colorHex!.substring(2) : colorHex!;
      if (cleanHex.length == 6) cleanHex = 'FF$cleanHex';
      return Color(int.parse(cleanHex, radix: 16));
    } catch (e) {
      return Colors.grey; // Fallback on error
    }
  }

  // Helper to convert codePoint string to IconData object
  IconData get icon {
    if (iconCodePoint == null || iconCodePoint!.isEmpty) return Icons.category; // Default icon
    try {
      return IconData(int.parse(iconCodePoint!), fontFamily: 'MaterialIcons');
    } catch (e) {
      return Icons.category; // Fallback on error
    }
  }
}