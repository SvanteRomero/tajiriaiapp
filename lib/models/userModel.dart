class AppUser {
  final String name;
  final String phoneNumber;
  late final double? monthlyIncome;
  final double savingsGoal;
  final String email;
  late final String? financialGoal;

  AppUser({
    required this.name,
    required this.phoneNumber,
    required this.monthlyIncome,
    required this.savingsGoal,
    required this.email,
  });
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
