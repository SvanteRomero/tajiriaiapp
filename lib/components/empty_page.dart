import 'package:flutter/material.dart';

/// A reusable widget for displaying empty states across the application.
/// 
/// This widget provides a consistent way to show empty states with an icon,
/// title, and description. It's used throughout the application when there's
/// no data to display or when a feature is not yet available.
/// 
/// Example usage:
/// ```dart
/// EmptyPage(
///   pageIconData: Icons.note,
///   pageTitle: 'No Notes',
///   pageDescription: 'Add your first note to get started',
/// )
/// ```
class EmptyPage extends StatelessWidget {
  /// Creates an empty page display.
  /// 
  /// All parameters are required to ensure a complete empty state message:
  /// - [pageIconData]: the icon to display
  /// - [pageTitle]: the main message
  /// - [pageDescription]: additional context or instructions
  const EmptyPage({
    super.key,
    required this.pageIconData,
    required this.pageTitle,
    required this.pageDescription,
  });

  /// The icon to display at the top of the empty state
  final IconData pageIconData;

  /// The main message explaining the empty state
  final String pageTitle;

  /// Additional context or instructions for the user
  final String pageDescription;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Large icon with muted color
          Icon(
            pageIconData,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),

          // Title text
          Text(
            pageTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),

          // Description text
          Text(
            pageDescription,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
