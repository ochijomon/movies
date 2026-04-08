import 'package:flutter/material.dart';

/// Design tokens for the tropical paradise admin theme.
/// All colors, spacing, radii, and typography constants live here.
abstract final class AppColors {
  static const Color background = Color(0xFFF6FCF8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFEEF8F1);
  static const Color primary = Color(0xFF74C69D);
  static const Color primaryDark = Color(0xFF4EA699);
  static const Color accent = Color(0xFF4EA699);
  static const Color sand = Color(0xFFF8F5EF);
  static const Color coral = Color(0xFFF2B48C);
  static const Color textPrimary = Color(0xFF23312B);
  static const Color textSecondary = Color(0xFF6C7F75);
  static const Color divider = Color(0xFFDCEDE3);
  static const Color error = Color(0xFFD9534F);
  static const Color success = Color(0xFF5CB85C);
  static const Color warning = Color(0xFFF0AD4E);
  static const Color sidebarBg = Color(0xFF23312B);
  static const Color sidebarText = Color(0xFFB8CFC3);
  static const Color sidebarActive = Color(0xFF74C69D);
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double card = 16;
}

abstract final class AppShadows {
  static List<BoxShadow> get soft => [
        BoxShadow(
          color: const Color(0xFF23312B).withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get medium => [
        BoxShadow(
          color: const Color(0xFF23312B).withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];
}

abstract final class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}
