import 'package:flutter/material.dart';

/// Tabs widget for salaries module.
class SalaryTabs extends StatelessWidget {
  const SalaryTabs({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
  });

  final int selectedTab;
  final void Function(int) onTabChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SalaryTab(
              label: 'Employés Fixes',
              index: 0,
              isSelected: selectedTab == 0,
              onTap: () => onTabChanged(0),
            ),
          ),
          Expanded(
            child: _SalaryTab(
              label: 'Paiements Production',
              index: 1,
              isSelected: selectedTab == 1,
              onTap: () => onTabChanged(1),
            ),
          ),
          Expanded(
            child: _SalaryTab(
              label: 'Historique',
              index: 2,
              isSelected: selectedTab == 2,
              onTap: () => onTabChanged(2),
            ),
          ),
          Expanded(
            child: _SalaryTab(
              label: 'Analyses',
              index: 3,
              isSelected: selectedTab == 3,
              onTap: () => onTabChanged(3),
            ),
          ),
        ],
      ),
    );
  }
}

class _SalaryTab extends StatelessWidget {
  const _SalaryTab({
    required this.label,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
