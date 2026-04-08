import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

enum ScreenType { mobile, tablet, desktop }

/// Determines the current screen type based on width.
ScreenType getScreenType(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < Breakpoints.mobile) return ScreenType.mobile;
  if (width < Breakpoints.desktop) return ScreenType.tablet;
  return ScreenType.desktop;
}

/// Responsive layout builder that provides the current screen type.
class ResponsiveLayout extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenType screenType) builder;

  const ResponsiveLayout({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final type = getScreenType(context);
        return builder(context, type);
      },
    );
  }
}
