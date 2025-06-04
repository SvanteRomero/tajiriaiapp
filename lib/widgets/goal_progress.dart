import 'package:flutter/material.dart';

class GoalProgress extends StatelessWidget {
  final String title;
  final double progress;
  final double target;
  final String remainingDays;
  final String Function(double) formatCurrency;
  final VoidCallback onEditPressed;
  final VoidCallback onBudgetPressed;

  const GoalProgress({
    Key? key,
    required this.title,
    required this.progress,
    required this.target,
    required this.remainingDays,
    required this.formatCurrency,
    required this.onEditPressed,
    required this.onBudgetPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${(progress * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      // Progress bar
      Container(
        height: 4,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.15),
            color: progress >= 1.0
                ? const Color(0xFF64B5F6)
                : const Color(0xFF90CAF9),
            minHeight: 4,
          ),
        ),
      ),
      const SizedBox(height: 4),
      // Goal details
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Target: ${formatCurrency(target)}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
          Text(
            remainingDays,
            style: TextStyle(
              color: DateTime.now().isAfter(DateTime.now()) 
                  ? Colors.red[300]
                  : Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      // Action buttons
      Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onEditPressed,
              icon: Icon(
                title.isEmpty ? Icons.add : Icons.edit,
                size: 16,
              ),
              label: Text(
                title.isEmpty ? 'Add Goal' : 'Edit Goal',
                style: const TextStyle(fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onBudgetPressed,
              icon: const Icon(Icons.account_balance, size: 16),
              label: const Text(
                'Add Budget',
                style: TextStyle(fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
