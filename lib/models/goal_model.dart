import 'package:flutter/foundation.dart';

/// A data model representing a financial savings goal.
/// 
/// This model is used throughout the application to manage and track user's
/// savings goals. It includes properties for goal identification, target amount,
/// deadline, and various metadata about the goal's nature and status.
/// 
/// The model provides methods for serialization to and from Firestore,
/// making it easy to persist and retrieve goal data.
class Goal {
  /// Unique identifier for the goal, typically from Firestore
  final String id;

  /// Title or description of the savings goal
  final String title;

  /// Target amount to save in the currency's smallest unit (e.g., cents)
  final int target;

  /// Deadline by which the goal should be achieved
  final DateTime deadline;

  /// Priority level of the goal (e.g., 'High', 'Medium', 'Low')
  final String priority;

  /// Frequency of savings contributions (e.g., 'weekly', 'monthly')
  final String frequency;

  /// Optional category associated with this goal for budget tracking
  final String? linkedCategory;

  /// Current status of the goal (e.g., 'active', 'completed', 'cancelled')
  final String status;

  /// Timestamp when the goal was created
  final DateTime createdAt;

  /// Creates a new Goal instance.
  /// 
  /// [id] defaults to empty string and is typically set when the goal is saved to Firestore.
  /// [priority] defaults to 'Medium'.
  /// [frequency] defaults to 'weekly'.
  /// [status] defaults to 'active'.
  /// [createdAt] defaults to current timestamp if not provided.
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

  /// Creates a Goal instance from a Firestore document.
  /// 
  /// [data] is the document data from Firestore.
  /// [documentId] is the Firestore document ID.
  /// 
  /// Handles null values and provides defaults for optional fields.
  /// Parses date strings into DateTime objects.
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

  /// Converts the Goal instance to a map for Firestore storage.
  /// 
  /// Converts DateTime objects to ISO 8601 strings for consistent storage.
  /// Includes all fields except the id, which is managed by Firestore.
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
