import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers.dart';
import '../../../../domain/entities/cylinder.dart';
import 'retail_cylinder_list.dart';
import 'retail_kpi_section.dart';

/// Onglet nouvelle vente pour la vente au détail.
class RetailNewSaleTab extends ConsumerWidget {
  const RetailNewSaleTab({
    super.key,
    required this.onCylinderTap,
  });

  final ValueChanged<Cylinder> onCylinderTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cylindersAsync = ref.watch(cylindersProvider);
    String? enterpriseId = 'default_enterprise'; // TODO: depuis contexte

    return CustomScrollView(
      slivers: [
        // KPI Cards
        const RetailKpiSection(),
        // Title and subtitle
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              children: [
                Text(
                  'Vente au Détail',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.normal,
                    color: const Color(0xFF101828),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sélectionnez la bouteille pour commencer la vente',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 16,
                    color: const Color(0xFF4A5565),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        // Cylinder cards
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          sliver: cylindersAsync.when(
            data: (cylinders) => RetailCylinderList(
              cylinders: cylinders,
              enterpriseId: enterpriseId ?? 'default_enterprise',
              onCylinderTap: onCylinderTap,
            ),
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Erreur: $e')),
            ),
          ),
        ),
      ],
    );
  }
}

