/// AppUser represents a user in the Tajiri AI application
/// Stores personal information and financial goals
class AppUser {
  /// User's full name
  final String name;

  /// User's contact phone number
  final String phoneNumber;

  /// User's monthly income
  /// Can be null if not yet provided
  /// Marked as late since it might be updated after initial creation
  late final double? monthlyIncome;

  /// User's target savings goal amount
  final double savingsGoal;

  /// User's email address
  final String email;

  /// User's financial goal description
  /// Can be null if not yet set
  /// Marked as late since it might be updated after initial creation
  late final String? financialGoal;

  /// Creates a new AppUser instance
  /// 
  /// Required parameters:
  /// - [name]: User's full name
  /// - [phoneNumber]: User's contact number
  /// - [monthlyIncome]: User's monthly income (can be null)
  /// - [savingsGoal]: User's target savings amount
  /// - [email]: User's email address
  AppUser({
    required this.name,
    required this.phoneNumber,
    required this.monthlyIncome,
    required this.savingsGoal,
    required this.email,
  });

  // TODO: Implement JSON serialization methods
  // /// Converts AppUser instance to JSON format for storage
  // Map<String, dynamic> toJson() => {
  //       'name': name,
  //       'email': email,
  //       'phoneNumber': phoneNumber,
  //       'monthlyIncome': monthlyIncome,
  //       'savingsGoal': savingsGoal,
  //       'financialGoal': financialGoal,
  //     };
  //
  // /// Creates an AppUser instance from JSON data
  // factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
  //       name: json['name'],
  //       email: json['email'],
  //       phoneNumber: json['phoneNumber'],
  //       monthlyIncome: json['monthlyIncome'] ?? 0.0,
  //       savingsGoal: json['savingsGoal'] ?? 0.0,
  //       financialGoal: json['financialGoal'] ?? '',
  //     );
}
