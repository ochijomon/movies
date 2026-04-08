import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Small badge displaying a rating value with color coding.
class RatingBadge extends StatelessWidget {
  final double rating;
  final double fontSize;

  const RatingBadge({super.key, required this.rating, this.fontSize = 12});

  Color get _color {
    if (rating >= 4.0) return AppColors.success;
    if (rating >= 3.0) return AppColors.primary;
    if (rating >= 2.0) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: fontSize + 2, color: _color),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip widget for genres, tags, etc.
class AppChip extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;

  const AppChip({super.key, required this.label, this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.surfaceSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
