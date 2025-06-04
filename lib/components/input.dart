import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A reusable styled input field component that provides consistent
/// styling and behavior across the application.
/// 
/// This component wraps Flutter's TextFormField with custom styling
/// and additional features like input formatting and validation.
class StyledInput extends StatelessWidget {
  /// Creates a styled input field.
  const StyledInput({
    super.key,
    required this.label,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.inputFormatters,
    this.enabled = true,
    this.autofocus = false,
    this.hintText,
  });

  /// The label text displayed above the input field
  final String label;

  /// Controller for managing the input text
  final TextEditingController controller;

  /// Optional validation function
  final String? Function(String?)? validator;

  /// Keyboard type for the input field
  final TextInputType? keyboardType;

  /// Whether to obscure the input text (for passwords)
  final bool obscureText;

  /// Optional icon displayed at the start of the input field
  final IconData? prefixIcon;

  /// Optional icon displayed at the end of the input field
  final IconData? suffixIcon;

  /// Callback function when the input value changes
  final void Function(String)? onChanged;

  /// Input formatters for restricting or formatting input
  final List<TextInputFormatter>? inputFormatters;

  /// Whether the input field is enabled
  final bool enabled;

  /// Whether the input field should autofocus
  final bool autofocus;

  /// Optional hint text displayed when the input is empty
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input label
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Input field
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          onChanged: onChanged,
          inputFormatters: inputFormatters,
          enabled: enabled,
          autofocus: autofocus,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: Colors.grey[600])
                : null,
            suffixIcon: suffixIcon != null
                ? Icon(suffixIcon, color: Colors.grey[600])
                : null,
            filled: true,
            fillColor: enabled ? Colors.grey[50] : Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.red[400]!,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.red[400]!,
                width: 1.5,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A specialized version of StyledInput for currency input.
/// 
/// This component includes currency-specific formatting and validation.
class CurrencyInput extends StatelessWidget {
  /// Creates a currency input field.
  const CurrencyInput({
    super.key,
    required this.label,
    required this.controller,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.autofocus = false,
    this.hintText,
  });

  /// The label text displayed above the input field
  final String label;

  /// Controller for managing the input text
  final TextEditingController controller;

  /// Optional validation function
  final String? Function(String?)? validator;

  /// Callback function when the input value changes
  final void Function(String)? onChanged;

  /// Whether the input field is enabled
  final bool enabled;

  /// Whether the input field should autofocus
  final bool autofocus;

  /// Optional hint text displayed when the input is empty
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return StyledInput(
      label: label,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: validator ?? (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter an amount';
        }
        if (double.tryParse(value.replaceAll(',', '')) == null) {
          return 'Please enter a valid amount';
        }
        return null;
      },
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
        TextInputFormatter.withFunction((oldValue, newValue) {
          final text = newValue.text;
          if (text.isEmpty) return newValue;

          // Remove existing commas
          String cleanText = text.replaceAll(',', '');

          // Check for valid decimal number
          if (!RegExp(r'^\d*\.?\d*$').hasMatch(cleanText)) {
            return oldValue;
          }

          // Format with commas
          final parts = cleanText.split('.');
          parts[0] = parts[0].replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          );

          final result = parts.join('.');
          return TextEditingValue(
            text: result,
            selection: TextSelection.collapsed(offset: result.length),
          );
        }),
      ],
      onChanged: onChanged,
      enabled: enabled,
      autofocus: autofocus,
      hintText: hintText,
      prefixIcon: Icons.attach_money,
    );
  }
}
