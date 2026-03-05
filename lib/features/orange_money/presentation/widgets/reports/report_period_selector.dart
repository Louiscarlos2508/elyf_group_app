import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import 'package:elyf_groupe_app/app/theme/design_tokens.dart' show AppRadius;

/// Period selector card for reports screen.
class ReportPeriodSelector extends StatelessWidget {
  const ReportPeriodSelector({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onStartDateSelected,
    required this.onEndDateSelected,
    required this.onTodaySelected,
    required this.onSevenDaysSelected,
    required this.onThisMonthSelected,
    required this.onLastMonthSelected,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onStartDateSelected;
  final VoidCallback onEndDateSelected;
  final VoidCallback onTodaySelected;
  final VoidCallback onSevenDaysSelected;
  final VoidCallback onThisMonthSelected;
  final VoidCallback onLastMonthSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ElyfCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      backgroundColor: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
      elevation: isDark ? 0 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 20,
                color: theme.colorScheme.onSurface,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Période de rapport',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Outfit',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: _ReportDateField(
                  label: 'Date de début',
                  date: startDate,
                  onTap: onStartDateSelected,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _ReportDateField(
                  label: 'Date de fin',
                  date: endDate,
                  onTap: onEndDateSelected,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _ReportQuickActions(
                  onTodaySelected: onTodaySelected,
                  onSevenDaysSelected: onSevenDaysSelected,
                  onThisMonthSelected: onThisMonthSelected,
                  onLastMonthSelected: onLastMonthSelected,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Date field widget for reports.
class _ReportDateField extends StatelessWidget {
  const _ReportDateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    date != null ? dateFormat.format(date!) : '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: date != null
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Quick actions widget for reports.
class _ReportQuickActions extends StatelessWidget {
  const _ReportQuickActions({
    required this.onTodaySelected,
    required this.onSevenDaysSelected,
    required this.onThisMonthSelected,
    required this.onLastMonthSelected,
  });

  final VoidCallback onTodaySelected;
  final VoidCallback onSevenDaysSelected;
  final VoidCallback onThisMonthSelected;
  final VoidCallback onLastMonthSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Raccourcis',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _QuickButton(label: 'Aujourd\'hui', onTap: onTodaySelected),
            _QuickButton(label: '7 jours', onTap: onSevenDaysSelected),
            _QuickButton(label: 'Ce mois', onTap: onThisMonthSelected),
            _QuickButton(label: 'Mois dernier', onTap: onLastMonthSelected),
          ],
        ),
      ],
    );
  }
}

class _QuickButton extends StatelessWidget {
  const _QuickButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.small),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
