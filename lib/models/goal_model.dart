import 'package:flutter/foundation.dart';

/// Defines the data model for a savings Goal.
class Goal {
  final String id;
  final String title;
  final int target;
  final DateTime deadline;
  final String priority;
  final String frequency;
  final String? linkedCategory;
  final String status;
  final DateTime createdAt;

  Goal({
    this.id = '',
    required this.title,
    required this.target,
    required this.deadline,
    this.priority = 'Medium',
    this.frequency = 'weekly',
    this.linkedCategory,
    this.status = 'active',
    DateTime? createdAt,
  }) : this.createdAt = createdAt ?? DateTime.now();

  /// Creates a Goal from a Firestore document map.
  factory Goal.fromMap(Map<String, dynamic> data, String documentId) {
    return Goal(
      id: documentId,
      title: data['title'] as String,
      target: data['target'] as int,
      deadline: DateTime.parse(data['deadline'] as String),
      priority: data['priority'] as String? ?? 'Medium',
      frequency: data['frequency'] as String? ?? 'weekly',
      linkedCategory: data['linkedCategory'] as String?,
      status: data['status'] as String? ?? 'active',
      createdAt: DateTime.parse(data['createdAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  /// Converts a Goal into a map for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'target': target,
      'deadline': deadline.toIso8601String(),
      'priority': priority,
      'frequency': frequency,
      'linkedCategory': linkedCategory,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
