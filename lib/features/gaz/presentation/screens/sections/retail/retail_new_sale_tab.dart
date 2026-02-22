import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';

import '../../../../../../core/tenant/tenant_provider.dart';
import '../../../../application/providers.dart';
import '../../../../domain/entities/cylinder.dart';
import 'retail_cylinder_list.dart';
import 'retail_kpi_section.dart';

/// Onglet nouvelle vente pour la vente au détail.
class RetailNewSaleTab extends ConsumerWidget {
  const RetailNewSaleTab({
    super.key,
    required this.onCylinderTap,
    this.onQuickExchange,
  });

  final ValueChanged<Cylinder> onCylinderTap;
  final ValueChanged<Cylinder>? onQuickExchange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cylindersAsync = ref.watch(cylindersProvider);
    // Récupérer l'entreprise active depuis le contexte
    final activeEnterpriseIdAsync = ref.watch(activeEnterpriseIdProvider);
    final enterpriseId = activeEnterpriseIdAsync.when(
      data: (id) => id ?? 'default_enterprise',
      loading: () => 'default_enterprise',
      error: (_, __) => 'default_enterprise',
    );

    return CustomScrollView(
      slivers: [
        // KPI Cards
        const RetailKpiSection(),

        // Cylinder cards
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          sliver: cylindersAsync.when(
            data: (cylinders) => RetailCylinderList(
              cylinders: cylinders,
              enterpriseId: enterpriseId,
              onCylinderTap: onCylinderTap,
              onQuickExchange: onQuickExchange,
            ),
            loading: () => SliverFillRemaining(
              child: AppShimmers.list(context),
            ),
            error: (e, _) =>
                SliverFillRemaining(child: Center(child: Text('Erreur: $e'))),
          ),
        ),
      ],
    );
  }
}
