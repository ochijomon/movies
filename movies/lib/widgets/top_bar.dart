import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Top application bar with title, notifications, and profile.
class AppTopBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onMenuTap;
  final bool showMenu;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onProfileTap;

  const AppTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onMenuTap,
    this.showMenu = false,
    this.onSettingsTap,
    this.onNotificationsTap,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(color: AppColors.textPrimary.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          if (showMenu)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: IconButton(icon: const Icon(Icons.menu_rounded), onPressed: onMenuTap, tooltip: 'Menu'),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          _TopBarAction(icon: Icons.notifications_none_rounded, badgeCount: 0, onTap: onNotificationsTap ?? () {}),
          const SizedBox(width: AppSpacing.sm),
          _TopBarAction(icon: Icons.settings_outlined, onTap: onSettingsTap ?? () {}),
          const SizedBox(width: AppSpacing.md),
          GestureDetector(
            onTap: onProfileTap,
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.surfaceSecondary,
              child: Icon(Icons.person_outline, color: AppColors.accent, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBarAction extends StatelessWidget {
  final IconData icon;
  final int badgeCount;
  final VoidCallback onTap;

  const _TopBarAction({required this.icon, this.badgeCount = 0, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(icon: Icon(icon, color: AppColors.textSecondary, size: 22), onPressed: onTap, splashRadius: 20),
        if (badgeCount > 0)
          Positioned(
            right: 6, top: 6,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(color: AppColors.coral, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text('$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
            ),
          ),
      ],
    );
  }
}
