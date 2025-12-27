import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../shared/utils/currency_formatter.dart';
import '../../../../application/providers.dart';
import '../../../../domain/entities/gas_sale.dart';
import '../../../../domain/services/gaz_calculation_service.dart';
import '../../../widgets/retail_kpi_card.dart';

/// Section des KPI cards pour la vente au détail.
class RetailKpiSection extends ConsumerWidget {
  const RetailKpiSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(gasSalesProvider);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: salesAsync.when(
          data: (sales) {
            final retailSales = sales
                .where((s) => s.saleType == SaleType.retail)
                .toList();
            // Utiliser le service pour les calculs
            final todaySales = GazCalculationService
                .calculateTodaySalesByType(retailSales, SaleType.retail);
            final totalToday = GazCalculationService
                .calculateTodayRevenueByType(retailSales, SaleType.retail);

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                if (isWide) {
                  return Row(
                    children: [
                      Expanded(
                        child: RetailKpiCard(
                          title: 'Ventes aujourd\'hui',
                          value: '${todaySales.length}',
                          icon: Icons.shopping_cart,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: RetailKpiCard(
                          title: 'Total du jour',
                          value: CurrencyFormatter.formatDouble(totalToday),
                          subtitle: 'FCFA',
                          icon: Icons.attach_money,
                        ),
                      ),
                    ],
                  );
                }

                // Mobile: stack vertically
                return Column(
                  children: [
                    RetailKpiCard(
                      title: 'Ventes aujourd\'hui',
                      value: '${todaySales.length}',
                      icon: Icons.shopping_cart,
                    ),
                    const SizedBox(height: 16),
                    RetailKpiCard(
                      title: 'Total du jour',
                      value: CurrencyFormatter.formatDouble(totalToday),
                      subtitle: 'FCFA',
                      icon: Icons.attach_money,
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

