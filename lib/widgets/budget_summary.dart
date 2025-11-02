import 'package:flutter/material.dart';

class BudgetSummary extends StatelessWidget {
  final double budget;
  final double spent;
  final String currency;

  const BudgetSummary({
    super.key,
    required this.budget,
    required this.spent,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = budget - spent;
    final percentage = budget > 0 ? (spent / budget * 100).clamp(0, 100) : 0.0;
    final isOverBudget = spent > budget;

    Color progressColor;
    IconData statusIcon;
    String statusText;

    if (isOverBudget) {
      progressColor = Colors.red;
      statusIcon = Icons.warning;
      statusText = 'Over budget!';
    } else if (percentage > 90) {
      progressColor = Colors.orange;
      statusIcon = Icons.info_outline;
      statusText = 'Almost there';
    } else if (percentage > 75) {
      progressColor = Colors.amber;
      statusIcon = Icons.trending_up;
      statusText = 'Watch spending';
    } else {
      progressColor = Colors.green;
      statusIcon = Icons.check_circle_outline;
      statusText = 'On track';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Budget progress bar
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: (percentage / 100).clamp(0, 1),
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Budget amounts
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildAmountColumn(
              'Spent',
              spent,
              currency,
              progressColor,
            ),
            _buildAmountColumn(
              'Remaining',
              remaining,
              currency,
              remaining >= 0 ? Colors.green : Colors.red,
            ),
            _buildAmountColumn(
              'Budget',
              budget,
              currency,
              Colors.grey.shade700,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Status indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: progressColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: progressColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                statusIcon,
                color: progressColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                statusText,
                style: TextStyle(
                  color: progressColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${percentage.toStringAsFixed(0)}% used',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountColumn(
    String label,
    double amount,
    String currency,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$currency ${amount.abs().toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
