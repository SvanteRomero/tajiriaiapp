// lib/core/models/goal_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

// The 'cancelled' status has been removed.
enum GoalStatus { active, completed, expired, abandoned }

class Goal {
  final String id;
  final String goalName;
  final double targetAmount;
  final double savedAmount;
  final DateTime startDate;
  final DateTime endDate;
  final double dailyLimit;
  final String timezone;
  final GoalStatus status;
  final String goalVersion;
  final int streakCount;
  final int graceDaysUsed;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? abandonedAt;

  Goal({
    required this.id,
    required this.goalName,
    required this.targetAmount,
    required this.savedAmount,
    required this.startDate,
    required this.endDate,
    required this.dailyLimit,
    required this.timezone,
    this.status = GoalStatus.active,
    this.goalVersion = 'v1.0',
    this.streakCount = 0,
    this.graceDaysUsed = 0,
    required this.createdAt,
    this.updatedAt,
    this.abandonedAt,
  });

  factory Goal.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Goal(
      id: doc.id,
      goalName: data['goal_name'] ?? '',
      targetAmount: (data['target_amount'] as num?)?.toDouble() ?? 0.0,
      savedAmount: (data['saved_amount'] as num?)?.toDouble() ?? 0.0,
      startDate: (data['start_date'] as Timestamp).toDate(),
      endDate: (data['end_date'] as Timestamp).toDate(),
      dailyLimit: (data['daily_limit'] as num?)?.toDouble() ?? 0.0,
      timezone: data['timezone'] ?? 'Africa/Dar_es_Salaam',
      status: (data['goal_status'] as String?) != null
          ? GoalStatus.values.firstWhere(
              (e) => e.toString().split('.').last == data['goal_status'],
              orElse: () => GoalStatus.active)
          : GoalStatus.active,
      goalVersion: data['goal_version'] ?? 'v1.0',
      streakCount: (data['streak_count'] as num?)?.toInt() ?? 0,
      graceDaysUsed: (data['grace_days_used'] as num?)?.toInt() ?? 0,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
      abandonedAt: (data['abandoned_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'goal_name': goalName,
      'target_amount': targetAmount,
      'saved_amount': savedAmount,
      'start_date': Timestamp.fromDate(startDate),
      'end_date': Timestamp.fromDate(endDate),
      'daily_limit': dailyLimit,
      'timezone': timezone,
      'goal_status': status.name,
      'goal_version': goalVersion,
      'streak_count': streakCount,
      'grace_days_used': graceDaysUsed,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'abandoned_at':
          abandonedAt != null ? Timestamp.fromDate(abandonedAt!) : null,
    };
  }
}