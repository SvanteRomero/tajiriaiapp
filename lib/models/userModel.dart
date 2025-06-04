/// A data model representing a user of the application.
/// 
/// This model stores essential user information including personal details,
/// financial information, and savings goals. It's used throughout the application
/// to manage user data and preferences.
class AppUser {
  /// User's display name
  final String name;

  /// User's contact phone number
  final String phoneNumber;

  /// User's monthly income (nullable for users who haven't set this)
  late final double? monthlyIncome;

  /// User's target savings goal amount
  final double savingsGoal;

  /// User's email address (used for authentication)
  final String email;

  /// User's financial goal description (nullable)
  late final String? financialGoal;

  /// Creates a new AppUser instance.
  /// 
  /// Required parameters ensure essential user information is always present:
  /// - [name]: user's display name
  /// - [phoneNumber]: contact number
  /// - [monthlyIncome]: monthly income (can be null)
  /// - [savingsGoal]: target savings amount
  /// - [email]: user's email address
  AppUser({
    required this.name,
    required this.phoneNumber,
    required this.monthlyIncome,
    required this.savingsGoal,
    required this.email,
  });

  /// Converts the AppUser instance to a JSON map for Firestore storage.
  /// 
  /// This method is essential for persisting user data to Firestore.
  /// All fields are included in the conversion, with nullable fields
  /// being handled appropriately.
  Map<String, dynamic> toJson() => {
    'name': name,
    'phoneNumber': phoneNumber,
    'email': email,
    'monthlyIncome': monthlyIncome,
    'savingsGoal': savingsGoal,
    'financialGoal': financialGoal,
  };

  /// Creates an AppUser instance from a Firestore document map.
  /// 
  /// This factory constructor handles the conversion of Firestore data
  /// back into an AppUser object. It includes default values for nullable fields
  /// to ensure the application can handle incomplete data gracefully.
  /// 
  /// [json] is the document data from Firestore.
  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    name: json['name'] as String,
    phoneNumber: json['phoneNumber'] as String,
    email: json['email'] as String,
    monthlyIncome: (json['monthlyIncome'] as num?)?.toDouble() ?? 0.0,
    savingsGoal: (json['savingsGoal'] as num?)?.toDouble() ?? 0.0,
  )..financialGoal = json['financialGoal'] as String?;

  /// Creates a copy of this AppUser with optional field updates.
  /// 
  /// This method is useful for updating specific fields while maintaining
  /// immutability of the original object.
  AppUser copyWith({
    String? name,
    String? phoneNumber,
    double? monthlyIncome,
    double? savingsGoal,
    String? email,
    String? financialGoal,
  }) {
    return AppUser(
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      savingsGoal: savingsGoal ?? this.savingsGoal,
      email: email ?? this.email,
    )..financialGoal = financialGoal ?? this.financialGoal;
  }

  @override
  String toString() {
    return 'AppUser(name: $name, email: $email, monthlyIncome: $monthlyIncome, savingsGoal: $savingsGoal)';
  }
}
