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
  });

  final List<Cylinder> cylinders;
  final String enterpriseId;
  final ValueChanged<Cylinder> onCylinderTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Decision based on screen width using MediaQuery to avoid LayoutBuilder/Sliver conflict
    final isWide = MediaQuery.of(context).size.width > 800;

    if (cylinders.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_fire_department_outlined, size: 64, color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              Text('Aucune bouteille configurée', style: theme.textTheme.titleMedium),
            ],
          ),
        ),
      );
    }

    // Use a single SliverToBoxAdapter and put the conditional logic inside
    return SliverToBoxAdapter(
      child: isWide
          ? Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 16,
        children: cylinders.map((cylinder) {
          return _CylinderCardWithStock(
            cylinder: cylinder,
            enterpriseId: enterpriseId,
            onTap: () => onCylinderTap(cylinder),
          );
        }).toList(),
      )
          : SizedBox(
        height: 420,
        child: ListView.separated( // Use ListView for better performance than SingleChildScrollView+Row
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: cylinders.length,
          separatorBuilder: (context, index) => const SizedBox(width: 16),
          itemBuilder: (context, index) {
            final cylinder = cylinders[index];
            return _CylinderCardWithStock(
              cylinder: cylinder,
              enterpriseId: enterpriseId,
              onTap: () => onCylinderTap(cylinder),
            );
          },
        ),
      ),
    );
  }
}

class _CylinderCardWithStock extends ConsumerWidget {
  const _CylinderCardWithStock({
    required this.cylinder,
    required this.enterpriseId,
    required this.onTap,
  });

  final Cylinder cylinder;
  final String enterpriseId;
  final VoidCallback onTap;

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
        );
      },
      loading: () => Container(
        width: 260,
        height: 400,
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
        width: 260,
        height: 400,
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
