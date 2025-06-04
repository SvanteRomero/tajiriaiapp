import 'package:flutter/foundation.dart';

/// Goal represents a financial savings target in the Tajiri AI application
/// It includes details about the target amount, deadline, and tracking metadata
class Goal {
  /// Unique identifier for the goal
  final String id;

  /// Title/name of the goal (e.g., "Buy a Car", "Emergency Fund")
  final String title;

  /// Target amount to save in the currency's smallest unit
  /// For example, 100000 represents $1,000.00
  final int target;

  /// Deadline by which the goal should be achieved
  final DateTime deadline;

  /// Priority level of the goal (Low, Medium, High)
  /// Defaults to 'Medium' if not specified
  final String priority;

  /// Frequency of savings contributions (daily, weekly, monthly)
  /// Defaults to 'weekly' if not specified
  final String frequency;

  /// Optional category linking the goal to specific transaction types
  /// Helps in tracking progress through related transactions
  final String? linkedCategory;

  /// Current status of the goal (active, completed, cancelled)
  /// Defaults to 'active' when created
  final String status;

  /// Timestamp when the goal was created
  /// Used for tracking goal lifetime and analytics
  final DateTime createdAt;

  /// Creates a new Goal instance
  /// 
  /// Required parameters:
  /// - [title]: Name of the goal
  /// - [target]: Amount to save
  /// - [deadline]: Target completion date
  /// 
  /// Optional parameters:
  /// - [id]: Unique identifier (defaults to empty string)
  /// - [priority]: Importance level (defaults to 'Medium')
  /// - [frequency]: Savings frequency (defaults to 'weekly')
  /// - [linkedCategory]: Associated transaction category
  /// - [status]: Current state (defaults to 'active')
  /// - [createdAt]: Creation timestamp (defaults to current time)
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

  /// Creates a Goal instance from Firestore document data
  /// 
  /// Parameters:
  /// - [data]: Map containing goal data from Firestore
  /// - [documentId]: Firestore document ID to use as goal ID
  /// 
  /// Handles null values and provides defaults for optional fields
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

  /// Converts the Goal instance to a map for Firestore storage
  /// 
  /// Returns a map with all goal properties
  /// Dates are converted to ISO 8601 strings for consistent storage
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
