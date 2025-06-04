import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// CustomInput is a reusable form input widget with consistent styling and validation
/// It wraps TextFormField with predefined styling and additional functionality
class CustomInput extends StatelessWidget {
  /// Creates a CustomInput widget
  /// 
  /// Required parameter:
  /// - [controller]: Controls the text being edited
  /// 
  /// Optional parameters:
  /// - [label]: Text label above the input field
  /// - [hint]: Placeholder text inside the input field
  /// - [validator]: Function to validate input value
  /// - [keyboardType]: Type of keyboard to display
  /// - [obscureText]: Whether to hide the input text
  /// - [prefixIcon]: Icon to display before the input
  /// - [suffixIcon]: Icon to display after the input
  /// - [onChanged]: Callback for when text changes
  /// - [inputFormatters]: List of input formatting rules
  /// - [maxLines]: Maximum number of lines for input
  /// - [maxLength]: Maximum length of input text
  /// - [enabled]: Whether the input is interactive
  const CustomInput({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.inputFormatters,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
  });

  /// Controller for the text field
  final TextEditingController controller;

  /// Label text displayed above the input
  final String? label;

  /// Placeholder text shown when input is empty
  final String? hint;

  /// Function to validate the input value
  final String? Function(String?)? validator;

  /// Type of keyboard to show (e.g., email, number)
  final TextInputType keyboardType;

  /// Whether to hide the input text (for passwords)
  final bool obscureText;

  /// Icon to display at the start of the input
  final IconData? prefixIcon;

  /// Icon to display at the end of the input
  final IconData? suffixIcon;

  /// Callback triggered when text changes
  final void Function(String)? onChanged;

  /// Rules for formatting input text
  final List<TextInputFormatter>? inputFormatters;

  /// Maximum number of lines for the input
  final int maxLines;

  /// Maximum number of characters allowed
  final int? maxLength;

  /// Whether the input is enabled for interaction
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon != null ? Icon(suffixIcon) : null,
        // Consistent padding for all inputs
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      maxLength: maxLength,
      enabled: enabled,
      // Style settings for consistent look
      style: const TextStyle(
        fontSize: 16,
      ),
    );
  }
}

/// Common validation functions for inputs
class InputValidators {
  /// Validates email format
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

  /// Validates password requirements
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validates required fields
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  /// Validates numeric input
  static String? numeric(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    if (double.tryParse(value) == null) {
      return 'Enter a valid number';
    }
    return null;
  }

  /// Validates phone number format
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    final regex = RegExp(r'^\+?[\d\s-]{10,}$');
    if (!regex.hasMatch(value)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  /// Creates a minimum length validator
  static String? Function(String?) minLength(int length) {
    return (String? value) {
      if (value == null || value.length < length) {
        return 'Must be at least $length characters';
      }
      return null;
    };
  }
}
