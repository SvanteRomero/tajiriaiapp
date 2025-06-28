import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum SnackbarType { success, error, info }

void showCustomSnackbar(BuildContext context, String message,
    {SnackbarType type = SnackbarType.success}) {
  Color color;
  IconData icon;

  switch (type) {
    case SnackbarType.success:
      color = Colors.green.shade600;
      icon = Icons.check_circle_outline;
      break;
    case SnackbarType.error:
      color = Colors.red.shade600;
      icon = Icons.error_outline;
      break;
    case SnackbarType.info:
      color = Colors.amber.shade800;
      icon = Icons.info_outline;
      break;
  }

  final snackbar = SnackBar(
    content: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ),
    backgroundColor: Colors.transparent,
    elevation: 0,
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.all(16),
    padding: EdgeInsets.zero,
  );

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(snackbar);
}