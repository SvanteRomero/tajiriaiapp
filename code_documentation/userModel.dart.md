# User Model (userModel.dart)

## Overview

This file defines the AppUser model for the Tajiri AI application. It encapsulates user profile information and financial details, providing a structured way to manage user data.

## Key Components

### AppUser Class

```dart
class AppUser {
  final String name;
  final String phoneNumber;
  late final double? monthlyIncome;
  final double savingsGoal;
  final String email;
  late final String? financialGoal;
}
```

- User information
- Financial data
- Optional fields

## Core Functionality

### Constructor

```dart
AppUser({
  required this.name,
  required this.phoneNumber,
  required this.monthlyIncome,
  required this.savingsGoal,
  required this.email,
});
```

- Required fields
- Optional fields
- Late initialization

### JSON Serialization

#### To JSON

```dart
Map<String, dynamic> toJson() => {
  'name': name,
  'phoneNumber': phoneNumber,
  'email': email,
  'monthlyIncome': monthlyIncome,
  'savingsGoal': savingsGoal,
  'financialGoal': financialGoal,
};
```

- Data formatting
- Null handling
- Complete mapping

#### From JSON

```dart
factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
  name: json['name'] as String,
  phoneNumber: json['phoneNumber'] as String,
  email: json['email'] as String,
  monthlyIncome: (json['monthlyIncome'] as num?)?.toDouble() ?? 0.0,
  savingsGoal: (json['savingsGoal'] as num).toDouble(),
)..financialGoal = json['financialGoal'] as String?;
```

- Data parsing
- Default values
- Type conversion

## Best Practices Implemented

1. **Immutability**
   - Final fields
   - Copy operations
   - Safe updates

2. **Null Safety**
   - Optional fields
   - Default values
   - Safe access

3. **Serialization**
   - Clean conversion
   - Type handling
   - Error checks

4. **Equality**
   - Value comparison
   - Hash generation
   - Collection support

## Technical Considerations

1. **Data Safety**
   - Type checking
   - Null safety
   - Value validation

2. **Performance**
   - Efficient copying
   - Quick comparison
   - Fast serialization

3. **Usability**
   - Clear API
   - Easy updates
   - Simple creation

## Notes

- Core user model
- Complete functionality
- Clean implementation
- Good practices
