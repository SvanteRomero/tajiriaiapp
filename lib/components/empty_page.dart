import 'package:flutter/material.dart';

class EmptyPage extends StatelessWidget {
  const EmptyPage({
    super.key,
    required this.pageIconData,
    required this.pageTitle,
    required this.pageDescription,
  });
  final IconData pageIconData;
  final String pageTitle;
  final String pageDescription;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(pageIconData, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            pageTitle, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            textAlign: TextAlign.center,
            pageDescription,
            style: TextStyle(fontSize: 16, color: Colors.grey[600], ),
          ),
        ],
      ),
    );
  }
}
