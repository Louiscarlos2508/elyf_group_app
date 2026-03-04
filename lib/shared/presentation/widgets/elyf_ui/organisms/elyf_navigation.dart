
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:elyf_groupe_app/app/theme/app_colors.dart';

/// A premium, glassmorphic bottom navigation bar.
class ElyfBottomNavigationBar extends StatelessWidget {
  const ElyfBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.moduleId,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<ElyfNavigationDestination> destinations;
  final String? moduleId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      // Ensure it sits above content safely
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).padding.bottom + 16),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: destinations.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = index == selectedIndex;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildNavItem(
                    context,
                    item,
                    isSelected,
                    () => onDestinationSelected(index),
                    moduleId,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, ElyfNavigationDestination item, bool isSelected, VoidCallback onTap, String? moduleId) {
    final theme = Theme.of(context);
    final moduleColor = AppColors.getModuleColor(moduleId);
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? moduleColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              color: isSelected 
                  ? moduleColor 
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                item.label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: moduleColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ElyfNavigationDestination {
  final IconData icon;
  final String label;

  const ElyfNavigationDestination({required this.icon, required this.label});
}

/// A premium, glassmorphic side navigation rail for desktop/tablet.
class ElyfNavigationRail extends StatelessWidget {
  const ElyfNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.moduleId,
    this.extended = false,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<ElyfNavigationDestination> destinations;
  final String? moduleId;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = extended ? 240.0 : 88.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24), // Spacing after AppBar
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: destinations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = destinations[index];
                final isSelected = index == selectedIndex;

                return _RailItem(
                  icon: item.icon,
                  label: item.label,
                  isSelected: isSelected,
                  extended: extended,
                  onTap: () => onDestinationSelected(index),
                  moduleId: moduleId,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.extended,
    required this.onTap,
    this.moduleId,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final bool extended;
  final VoidCallback onTap;
  final String? moduleId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final moduleColor = AppColors.getModuleColor(moduleId);

    // Determines text style based on selection
    final textStyle = theme.textTheme.labelLarge?.copyWith(
                  color: isSelected ? moduleColor : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  fontFamily: 'Outfit',
                );

    if (!extended) {
      return Tooltip(
        message: label,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 56,
              alignment: Alignment.center,
              decoration: isSelected
                  ? BoxDecoration(
                      color: moduleColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    )
                  : null,
              child: Icon(
                icon,
                color: isSelected ? moduleColor : theme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: isSelected
              ? BoxDecoration(
                  color: moduleColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: moduleColor.withValues(alpha: 0.1)),
                )
              : null,
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? moduleColor : theme.colorScheme.onSurfaceVariant,
                size: 22,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: textStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSelected) 
                Icon(
                  Icons.chevron_right, 
                  color: moduleColor,
                  size: 16
                ),
            ],
          ),
        ),
      ),
    );
  }
}
