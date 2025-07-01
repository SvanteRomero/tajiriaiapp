// lib/core/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final bool transactionalNotifications;
  final bool goalNotifications;
  final bool financialSummaries;
  final bool financialTips;
  final bool personalizedAlerts;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
    this.transactionalNotifications = true,
    this.goalNotifications = true,
    this.financialSummaries = true,
    this.financialTips = true,
    this.personalizedAlerts = true,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoUrl: data['photoUrl'],
      phoneNumber: data['phoneNumber'],
      transactionalNotifications: data['transactionalNotifications'] ?? true,
      goalNotifications: data['goalNotifications'] ?? true,
      financialSummaries: data['financialSummaries'] ?? true,
      financialTips: data['financialTips'] ?? true,
      personalizedAlerts: data['personalizedAlerts'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'transactionalNotifications': transactionalNotifications,
      'goalNotifications': goalNotifications,
      'financialSummaries': financialSummaries,
      'financialTips': financialTips,
      'personalizedAlerts': personalizedAlerts,
    };
  }
}