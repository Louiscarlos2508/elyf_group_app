import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../../../../shared/utils/currency_formatter.dart';
import '../../../../application/providers.dart';
import '../../../../domain/entities/gas_sale.dart';
import '../../../widgets/gaz_kpi_card.dart';
import 'package:elyf_groupe_app/features/gaz/domain/services/gaz_sales_calculation_service.dart';

/// Section des KPI cards pour la vente en gros.
class WholesaleKpiSection extends ConsumerWidget {
  const WholesaleKpiSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final salesAsync = ref.watch(gasSalesProvider);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: salesAsync.when(
          data: (sales) {
            // Utiliser le service pour les calculs wholesale
            final todaySales = GazSalesCalculationService.calculateTodaySalesByType(
              sales,
              SaleType.wholesale,
            );
            final totalToday =
                GazSalesCalculationService.calculateTodayRevenueByType(
                  sales,
                  SaleType.wholesale,
                );

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                if (isWide) {
                   return Row(
                    children: [
                      Expanded(
                        child: GazKpiCard(
                          title: 'Ventes du Jour',
                          value: '${todaySales.length}',
                          icon: Icons.assignment_outlined,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GazKpiCard(
                          title: 'Chiffre d\'Affaires (Gros)',
                          value: CurrencyFormatter.formatDouble(totalToday),
                          subtitle: 'FCFA',
                          icon: Icons.account_balance_wallet_outlined,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  );
                }

                 return Column(
                  children: [
                    GazKpiCard(
                      title: 'Ventes du Jour',
                      value: '${todaySales.length}',
                      icon: Icons.assignment_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    GazKpiCard(
                      title: 'Chiffre d\'Affaires (Gros)',
                      value: CurrencyFormatter.formatDouble(totalToday),
                      subtitle: 'FCFA',
                      icon: Icons.account_balance_wallet_outlined,
                      color: theme.colorScheme.secondary,
                    ),
                  ],
                );
              },
            );
          },
          loading: () => const SizedBox(
            height: 115,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

