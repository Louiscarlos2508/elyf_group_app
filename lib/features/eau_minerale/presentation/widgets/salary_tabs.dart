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
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SegmentedButton<int>(
        segments: const [
          ButtonSegment<int>(
            value: 0,
            label: Text('Fixes'),
            icon: Icon(Icons.people_outline_rounded, size: 18),
          ),
          ButtonSegment<int>(
            value: 1,
            label: Text('Production'),
            icon: Icon(Icons.factory_outlined, size: 18),
          ),
          ButtonSegment<int>(
            value: 2,
            label: Text('Histo'),
            icon: Icon(Icons.history_rounded, size: 18),
          ),
          ButtonSegment<int>(
            value: 3,
            label: Text('Stats'),
            icon: Icon(Icons.analytics_outlined, size: 18),
          ),
        ],
        selected: {selectedTab},
        onSelectionChanged: (Set<int> newSelection) {
          onTabChanged(newSelection.first);
        },
        style: SegmentedButton.styleFrom(
          backgroundColor: isDark 
              ? theme.colorScheme.surfaceContainerHigh 
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          selectedBackgroundColor: theme.colorScheme.primary,
          selectedForegroundColor: theme.colorScheme.onPrimary,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          visualDensity: VisualDensity.comfortable,
        ),
        showSelectedIcon: false,
      ),
    );
  }
}
