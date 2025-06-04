import 'package:flutter/material.dart';

/// EmptyPage is a reusable widget that displays a placeholder when content is unavailable
/// It shows a centered icon, title, and description to provide context to the user
class EmptyPage extends StatelessWidget {
  /// Creates an EmptyPage widget
  /// 
  /// Required parameters:
  /// - [pageIconData]: Icon to display at the top of the empty state
  /// - [pageTitle]: Main message explaining the empty state
  /// - [pageDescription]: Additional context or instructions for the user
  const EmptyPage({
    super.key,
    required this.pageIconData,
    required this.pageTitle,
    required this.pageDescription,
  });

  /// Icon to be displayed above the title
  /// Should be relevant to the empty state context
  final IconData pageIconData;

  /// Main message explaining why the page is empty
  /// Should be clear and concise (e.g., "No Transactions")
  final String pageTitle;

  /// Additional context or instructions for the user
  /// Can include action items (e.g., "Add transactions to see them here")
  final String pageDescription;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        // Center content vertically and horizontally
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Large icon with subtle grey color
          Icon(
            pageIconData,
            size: 80,
            color: Colors.grey[300]
          ),
          // Spacing between icon and title
          const SizedBox(height: 16),
          // Title text with medium emphasis
          Text(
            pageTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500
            ),
          ),
          // Spacing between title and description
          const SizedBox(height: 8),
          // Description text with lower emphasis
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
