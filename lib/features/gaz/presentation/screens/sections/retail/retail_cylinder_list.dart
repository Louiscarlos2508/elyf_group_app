import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers.dart';
import '../../../../domain/entities/cylinder.dart';
import '../../../widgets/cylinder_sale_card.dart';

/// Liste des bouteilles disponibles pour la vente.
class RetailCylinderList extends ConsumerWidget {
  const RetailCylinderList({
    super.key,
    required this.cylinders,
    required this.enterpriseId,
    required this.onCylinderTap,
    this.onQuickExchange,
  });

  final List<Cylinder> cylinders;
  final String enterpriseId;
  final ValueChanged<Cylinder> onCylinderTap;
  final ValueChanged<Cylinder>? onQuickExchange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (cylinders.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_fire_department_outlined,
                size: 64,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucune bouteille configurée',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          if (isWide) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: cylinders.map((cylinder) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _CylinderCardWithStock(
                    cylinder: cylinder,
                    enterpriseId: enterpriseId,
                    onTap: () => onCylinderTap(cylinder),
                    onQuickExchange: onQuickExchange != null ? () => onQuickExchange!(cylinder) : null,
                  ),
                );
              }).toList(),
            );
          }

          // Mobile: scrollable horizontal list
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: cylinders.map((cylinder) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _CylinderCardWithStock(
                    cylinder: cylinder,
                    enterpriseId: enterpriseId,
                    onTap: () => onCylinderTap(cylinder),
                    onQuickExchange: onQuickExchange != null ? () => onQuickExchange!(cylinder) : null,
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

class _CylinderCardWithStock extends ConsumerWidget {
  const _CylinderCardWithStock({
    required this.cylinder,
    required this.enterpriseId,
    required this.onTap,
    this.onQuickExchange,
  });

  final Cylinder cylinder;
  final String enterpriseId;
  final VoidCallback onTap;
  final VoidCallback? onQuickExchange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stocksAsync = ref.watch(
      cylinderStocksProvider((
        enterpriseId: enterpriseId,
        status: CylinderStatus.full,
        siteId: null,
      )),
    );

    return stocksAsync.when(
      data: (stocks) {
        final stock = stocks
            .where((s) => s.weight == cylinder.weight)
            .fold<int>(0, (sum, s) => sum + s.quantity);

        return CylinderSaleCard(
          cylinder: cylinder,
          stock: stock,
          onTap: onTap,
          onQuickExchange: onQuickExchange,
        );
      },
      loading: () => Container(
        width: 325,
        height: 512,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 1.3,
          ),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Container(
        width: 325,
        height: 512,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.1),
            width: 1.3,
          ),
        ),
        child: const Center(child: Icon(Icons.error)),
      ),
    );
  }
}
