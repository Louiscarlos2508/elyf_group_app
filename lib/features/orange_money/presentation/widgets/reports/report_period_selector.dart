import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart' as tokens;
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
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onStartDateSelected;
  final VoidCallback onEndDateSelected;
  final VoidCallback onTodaySelected;
  final VoidCallback onSevenDaysSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ElyfCard(
      padding: const EdgeInsets.all(tokens.AppSpacing.lg),
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
              const SizedBox(width: tokens.AppSpacing.sm),
              Text(
                'Période de rapport',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Outfit',
                ),
              ),
            ],
          ),
          const SizedBox(height: tokens.AppSpacing.xl),
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
  });

  final VoidCallback onTodaySelected;
  final VoidCallback onSevenDaysSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onTodaySelected,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.small),
                  ),
                ),
                child: const Text('Aujourd\'hui'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton(
                onPressed: onSevenDaysSelected,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.small),
                  ),
                ),
                child: const Text('7 jours'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
