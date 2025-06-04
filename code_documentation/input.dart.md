# Input Component (input.dart)

## Overview
This file implements a reusable input field component for the Tajiri AI application. It provides consistent styling, validation, and behavior across all form inputs in the application.

## Key Components

### CustomInput Widget
```dart
class CustomInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool obscureText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final void Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final int? maxLength;
  final bool enabled;
}
```
- Form input field
- Validation support
- Flexible configuration

### InputValidators Class
```dart
class InputValidators {
  static String? email(String? value);
  static String? password(String? value);
  static String? required(String? value);
  static String? numeric(String? value);
  static String? phone(String? value);
  static String? Function(String?) minLength(int length);
}
```
- Common validations
- Reusable rules
- Clear messages

## Core Functionality

### Input Configuration
```dart
TextFormField(
  controller: controller,
  decoration: InputDecoration(
    labelText: label,
    hintText: hint,
    border: const OutlineInputBorder(),
    prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
    suffixIcon: suffixIcon != null ? Icon(suffixIcon) : null,
  ),
)
```
- Clean styling
- Consistent look
- Flexible options

### Validation Functions

#### Email Validation
```dart
static String? email(String? value) {
  if (value == null || value.isEmpty) {
    return 'Email is required';
  }
  final regex = RegExp(r"^[^@]+@[^@]+\.[^@]+");
  if (!regex.hasMatch(value)) {
    return 'Enter a valid email';
  }
  return null;
}
```
- Format checking
- Required field
- Clear messages

#### Password Validation
```dart
static String? password(String? value) {
  if (value == null || value.isEmpty) {
    return 'Password is required';
  }
  if (value.length < 6) {
    return 'Password must be at least 6 characters';
  }
  return null;
}
```
- Length check
- Required field
- Security rules

## Usage Examples

### Basic Input
```dart
CustomInput(
  controller: textController,
  label: "Username",
  hint: "Enter your username",
)
```

### Email Input
```dart
CustomInput(
  controller: emailController,
  label: "Email",
  validator: InputValidators.email,
  keyboardType: TextInputType.emailAddress,
)
```

### Password Input
```dart
CustomInput(
  controller: passwordController,
  label: "Password",
  obscureText: true,
  validator: InputValidators.password,
)
```

## Best Practices Implemented

1. **Input Styling**
   - Consistent look
   - Clear labels
   - Visual feedback

2. **Validation**
   - Clear messages
   - Common rules
   - Easy reuse

3. **Configuration**
   - Flexible options
   - Clean defaults
   - Easy customization

4. **Code Organization**
   - Clear structure
   - Reusable parts
   - Good documentation

## Technical Considerations

1. **Styling**
   - Consistent borders
   - Proper padding
   - Clear typography

2. **Validation**
   - Regex patterns
   - Error messages
   - Rule combinations

3. **Performance**
   - Efficient validation
   - Quick feedback
   - Clean updates

4. **Usability**
   - Clear labels
   - Helpful hints
   - Error feedback

## Implementation Notes

1. **Input Structure**
   ```dart
   TextFormField(
     // Controller
     // Decoration
     // Validation
     // Formatting
   )
   ```
   - Clean layout
   - Clear structure
   - Easy maintenance

2. **Validation Rules**
   ```dart
   // Email regex
   r"^[^@]+@[^@]+\.[^@]+"

   // Phone regex
   r'^\+?[\d\s-]{10,}$'
   ```
   - Clear patterns
   - Good coverage
   - Easy updates

3. **Styling Constants**
   ```dart
   contentPadding: EdgeInsets.symmetric(
     horizontal: 16,
     vertical: 12,
   )
   ```
   - Consistent spacing
   - Clean look
   - Good readability

## Notes
- Reusable component
- Consistent validation
- Clean styling
- Good practices
