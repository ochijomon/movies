import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Data model for a sidebar navigation item.
class SidebarItemData {
  final IconData icon;
  final String label;

  const SidebarItemData({required this.icon, required this.label});
}

/// Full sidebar for desktop layout.
class AppSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<SidebarItemData> items;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBg,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(AppRadius.xl),
          bottomRight: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          // Logo / Brand
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.movie_filter_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + 4),
                const Text(
                  'MOVIES',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          // Navigation items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = index == selectedIndex;
                return _SidebarItem(
                  icon: item.icon,
                  label: item.label,
                  isSelected: isSelected,
                  onTap: () => onItemSelected(index),
                );
              },
            ),
          ),
          // Bottom section
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.person_outline, color: Colors.white, size: 18),
                  ),
                  SizedBox(width: AppSpacing.sm + 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Administrateur',
                          style: TextStyle(
                            color: AppColors.sidebarText,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: isSelected
            ? AppColors.sidebarActive.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 4,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? AppColors.sidebarActive : AppColors.sidebarText,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? AppColors.sidebarActive : AppColors.sidebarText,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact NavigationRail for tablet layout.
class AppNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<SidebarItemData> items;

  const AppNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onItemSelected,
      backgroundColor: AppColors.sidebarBg,
      indicatorColor: AppColors.sidebarActive.withValues(alpha: 0.15),
      leading: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xl),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: const Icon(Icons.movie_filter_outlined, color: Colors.white, size: 22),
        ),
      ),
      destinations: items
          .map(
            (item) => NavigationRailDestination(
              icon: Icon(item.icon, color: AppColors.sidebarText),
              selectedIcon: Icon(item.icon, color: AppColors.sidebarActive),
              label: Text(
                item.label,
                style: const TextStyle(color: AppColors.sidebarText, fontSize: 11),
              ),
            ),
          )
          .toList(),
    );
  }
}
