import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Reusable section card with title, optional action, and child content.
class SectionCard extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget child;
  final IconData? titleIcon;

  const SectionCard({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    required this.child,
    this.titleIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                if (titleIcon != null) ...[
                  Icon(titleIcon, size: 18, color: AppColors.accent),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (actionLabel != null)
                  TextButton(
                    onPressed: onAction,
                    child: Text(
                      actionLabel!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(),
          child,
        ],
      ),
    );
  }
}
