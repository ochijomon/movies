import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Primary action button.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isOutlined;
  final bool isSmall;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isOutlined = false,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final padding = isSmall
        ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
        : const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md);

    final textStyle = TextStyle(
      fontSize: isSmall ? 12 : 14,
      fontWeight: FontWeight.w600,
    );

    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon, size: isSmall ? 16 : 18) : const SizedBox.shrink(),
        label: Text(label, style: textStyle),
        style: OutlinedButton.styleFrom(padding: padding),
      );
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon, size: isSmall ? 16 : 18) : const SizedBox.shrink(),
      label: Text(label, style: textStyle),
      style: ElevatedButton.styleFrom(padding: padding),
    );
  }
}
