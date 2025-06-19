import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? phoneNumber;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoUrl: data['photoUrl'],
      phoneNumber: data['phoneNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
    };
  }
}

//   Map<String, dynamic> toJson() => {
//         'uid': uid,
//         'name': name,
//         'email': email,
//         'monthlyIncome': monthlyIncome,
//         'savingsGoal': savingsGoal,
//         'financialGoal': financialGoal,
//       };
//
//   factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
//         uid: json['uid'],
//         name: json['name'],
//         email: json['email'],
//         monthlyIncome: json['monthlyIncome'] ?? 0.0,
//         savingsGoal: json['savingsGoal'] ?? 0.0,
//         financialGoal: json['financialGoal'] ?? '',
//       );
// }
