import 'package:flutter/material.dart';

/// Tabs widget for gaz reports module - style eau_minerale.
class GazReportTabsV2 extends StatelessWidget {
  const GazReportTabsV2({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
  });

  final int selectedTab;
  final void Function(int) onTabChanged;

  static const _tabs = [
    _TabInfo('Ventes', Icons.local_fire_department_outlined),
    _TabInfo('Dépenses', Icons.receipt_long_outlined),
    _TabInfo('Bénéfices', Icons.trending_up),
    _TabInfo('Financier', Icons.account_balance),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;

        if (isWide) {
          return _buildWideLayout(theme);
        }
        return _buildCompactLayout(theme);
      },
    );
  }

  Widget _buildWideLayout(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _tabs.asMap().entries.map((entry) {
            return _buildTab(theme, entry.key, entry.value, false);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCompactLayout(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: _tabs.asMap().entries.map((entry) {
            return _buildTab(theme, entry.key, entry.value, true);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTab(ThemeData theme, int index, _TabInfo tab, bool compact) {
    final isSelected = selectedTab == index;

    return Padding(
      padding: const EdgeInsets.all(4),
      child: InkWell(
        onTap: () => onTabChanged(index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tab.icon,
                size: 18,
                color: isSelected
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                tab.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabInfo {
  const _TabInfo(this.label, this.icon);

  final String label;
  final IconData icon;
}