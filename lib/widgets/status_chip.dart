import 'package:flutter/material.dart';
import '../theme.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final bool compact;

  const StatusChip({
    super.key,
    required this.label,
    this.icon,
    this.color = AppColors.blue,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border, width: 2.2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 13 : 15, color: AppColors.ink),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
