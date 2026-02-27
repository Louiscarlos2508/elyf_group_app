import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../shared/presentation/widgets/elyf_ui/organisms/elyf_card.dart';
import '../../../../../../shared/presentation/widgets/elyf_ui/atoms/elyf_shimmer.dart';
import '../../application/providers.dart';
import '../../../../core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/features/gaz/domain/services/gaz_stock_calculation_service.dart';

/// Widget for Stock par capacité section showing full/empty counts.
class DashboardStockByCapacity extends ConsumerWidget {
  const DashboardStockByCapacity({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeEnterprise = ref.watch(activeEnterpriseProvider).value;
    final enterpriseId = activeEnterprise?.id ?? 'default_enterprise';

    final dashboardDataAsync = ref.watch(gazDashboardDataProviderComplete);
    final settingsAsync = ref.watch(
      gazSettingsProvider((
        enterpriseId: enterpriseId,
        moduleId: 'gaz',
      )),
    );

    return ElyfCard(
      isGlass: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Stock par capacité',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                Icons.inventory_2_outlined,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 20),
          settingsAsync.when(
            loading: () => Column(
              children: [
                ElyfShimmer.listTile(),
                const SizedBox(height: 8),
                ElyfShimmer.listTile(),
              ],
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (settings) => dashboardDataAsync.when(
              data: (data) {
                final metrics = GazStockCalculationService.calculateStockMetrics(
                  stocks: data.stocks,
                  pointsOfSale: data.pointsOfSale,
                  cylinders: data.cylinders,
                  transfers: data.transfers,
                  settings: activeEnterprise?.isPointOfSale == true ? null : settings,
                  targetEnterpriseId: enterpriseId,
                  isPOS: activeEnterprise?.isPointOfSale == true,
                );

                final weights = metrics.availableWeights;
                
                if (weights.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'Aucun stock enregistré',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: weights.map((weight) {
                    final capacityData = metrics.stockByCapacity[weight];
                    if (capacityData == null) return const SizedBox.shrink();

                    return _CapacityItem(
                      label: '${weight}kg',
                      full: capacityData.full,
                      empty: capacityData.empty,
                      inTransit: capacityData.inTransit,
                      issues: capacityData.defective + capacityData.leak,
                      isLast: weight == weights.last,
                    );
                  }).toList(),
                );
              },
              loading: () => Column(
                children: [
                  ElyfShimmer.listTile(),
                  const SizedBox(height: 8),
                  ElyfShimmer.listTile(),
                ],
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CapacityItem extends StatelessWidget {
  const _CapacityItem({
    required this.label,
    required this.full,
    required this.empty,
    this.inTransit = 0,
    this.issues = 0,
    this.isLast = false,
  });

  final String label;
  final int full;
  final int empty;
  final int inTransit;
  final int issues;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: !isLast
            ? Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  width: 1,
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StatusBadge(
                      label: '$full Pleines',
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(
                      label: '$empty Vides',
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    if (inTransit > 0) ...[
                      const SizedBox(width: 8),
                      _StatusBadge(
                        label: '$inTransit Transit',
                        color: Colors.orange,
                      ),
                    ],
                    if (issues > 0) ...[
                      const SizedBox(width: 8),
                      _StatusBadge(
                        label: '$issues Fuites',
                        color: theme.colorScheme.error,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Progress-like indicator
          _SmallIndicator(
            value: (full + empty) > 0 ? full / (full + empty) : 0,
            color: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _SmallIndicator extends StatelessWidget {
  const _SmallIndicator({required this.value, required this.color});
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            value: value,
            strokeWidth: 3,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        Text(
          '${(value * 100).toInt()}%',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
