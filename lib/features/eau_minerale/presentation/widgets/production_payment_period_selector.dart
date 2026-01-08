import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/production_period_config.dart';
import 'production_period_formatter.dart';

/// Selector for production payment period.
class ProductionPaymentPeriodSelector extends ConsumerWidget {
  const ProductionPaymentPeriodSelector({
    super.key,
    required this.period,
    required this.onPeriodChanged,
  });

  final String period;
  final ValueChanged<String> onPeriodChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final configAsync = ref.watch(productionPeriodConfigProvider);

    return configAsync.when(
      data: (config) {
        final now = DateTime.now();
        final periodNum = config.getPeriodForDate(now);
        final formatter = ProductionPeriodFormatter(config);
        final currentPeriod = formatter.formatPeriod(periodNum, now);

        return InkWell(
          onTap: () async {
            // For now, just use current period
            // In future, could show a dialog to select different period
            onPeriodChanged(currentPeriod);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Période / Semaine',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        period.isEmpty ? currentPeriod : period,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

