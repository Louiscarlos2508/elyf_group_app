import 'package:flutter/material.dart';

class SalesTabBar extends StatelessWidget {
  const SalesTabBar({
    super.key,
    required this.tabController,
    required this.tabs,
  });

  final TabController tabController;
  final List<String> tabs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: List.generate(
            tabs.length,
            (index) => _buildTab(context, index: index, label: tabs[index]),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(BuildContext context, {required int index, required String label}) {
    final theme = Theme.of(context);
    final isSelected = tabController.index == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => tabController.animateTo(index),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              color: isSelected
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
