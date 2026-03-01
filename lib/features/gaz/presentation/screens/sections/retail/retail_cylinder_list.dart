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

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: isWide
            ? Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 16,
                children: cylinders.map((cylinder) {
                  return SizedBox(
                    width: 200, // Fixed width only on desktop wrap
                    child: _CylinderCardWithStock(
                      cylinder: cylinder,
                      enterpriseId: enterpriseId,
                      onTap: () => onCylinderTap(cylinder),
                    ),
                  );
                }).toList(),
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cylinders.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemBuilder: (context, index) {
                  return _CylinderCardWithStock(
                    cylinder: cylinders[index],
                    enterpriseId: enterpriseId,
                    onTap: () => onCylinderTap(cylinders[index]),
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
      loading: () => const AspectRatio(
        aspectRatio: 0.75,
        child: Card(child: Center(child: CircularProgressIndicator())),
      ),
      error: (_, __) => const AspectRatio(
        aspectRatio: 0.75,
        child: Card(child: Center(child: Icon(Icons.error))),
      ),
    );
  }
}
