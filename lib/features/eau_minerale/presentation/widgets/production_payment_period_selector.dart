import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
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
            // Future: Show period picker dialog
            onPeriodChanged(currentPeriod);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.3),
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.date_range_rounded, color: theme.colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Période / Semaine',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        period.isEmpty ? currentPeriod : period,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.unfold_more_rounded, color: theme.colorScheme.onSurfaceVariant, size: 18),
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
