import 'package:flutter/material.dart';

enum GazReportTab {
  activity('Activité', Icons.local_fire_department_outlined),
  finance('Trésorerie', Icons.account_balance_wallet_outlined),
  stock('Stocks', Icons.inventory_2_outlined),
  posNetwork('Réseau POS', Icons.store_mall_directory_outlined);

  const GazReportTab(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Tabs widget for gaz reports module - style eau_minerale.
class GazReportTabsV2 extends StatelessWidget {
  const GazReportTabsV2({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
    this.showPosTab = false,
    this.isPOS = false,
  });

  final GazReportTab selectedTab;
  final void Function(GazReportTab) onTabChanged;
  final bool showPosTab;
  final bool isPOS;

  List<GazReportTab> get _tabs => [
        GazReportTab.activity,
        if (!isPOS) GazReportTab.finance,
        GazReportTab.stock,
        if (showPosTab) GazReportTab.posNetwork,
      ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tabs = _tabs;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;

        if (isWide) {
          return _buildWideLayout(theme, tabs);
        }
        return _buildCompactLayout(theme, tabs);
      },
    );
  }

  Widget _buildWideLayout(ThemeData theme, List<GazReportTab> tabs) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((tab) {
            return _buildTab(theme, tab, false);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCompactLayout(ThemeData theme, List<GazReportTab> tabs) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: tabs.map((tab) {
            return _buildTab(theme, tab, true);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTab(ThemeData theme, GazReportTab tab, bool compact) {
    final isSelected = selectedTab == tab;

    return Padding(
      padding: const EdgeInsets.all(4),
      child: InkWell(
        onTap: () => onTabChanged(tab),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
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
