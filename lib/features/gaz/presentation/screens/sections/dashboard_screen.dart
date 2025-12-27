import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/presentation/widgets/refresh_button.dart';
import '../../../application/providers.dart';
import '../../../domain/entities/cylinder.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/gas_sale.dart';
import '../../widgets/dashboard_stock_by_capacity.dart';
import 'dashboard/dashboard_kpi_section.dart';
import 'dashboard/dashboard_performance_section.dart';
import 'dashboard/dashboard_pos_performance_section.dart';

/// Professional dashboard screen for gaz module - matches Figma design.
class GazDashboardScreen extends ConsumerWidget {
  const GazDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(gasSalesProvider);
    final expensesAsync = ref.watch(gazExpensesProvider);
    final cylindersAsync = ref.watch(cylindersProvider);

    return CustomScrollView(
      slivers: [
        // Header section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Vue d'ensemble",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              color: const Color(0xFF101828),
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tableau de bord de gestion du gaz',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              color: const Color(0xFF4A5565),
                            ),
                      ),
                    ],
                  ),
                ),
                RefreshButton(
                  onRefresh: () {
                    ref.invalidate(gasSalesProvider);
                    ref.invalidate(cylindersProvider);
                    ref.invalidate(gazExpensesProvider);
                  },
                  tooltip: 'Actualiser le tableau de bord',
                ),
              ],
            ),
          ),
        ),

        // KPI Cards (4 cards in a row)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          sliver: SliverToBoxAdapter(
            child: salesAsync.when(
              data: (sales) => expensesAsync.when(
                data: (expenses) => cylindersAsync.when(
                  data: (cylinders) => DashboardKpiSection(
                    sales: sales,
                    expenses: expenses,
                    cylinders: cylinders,
                  ),
                  loading: () => const SizedBox(
                    height: 155,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                loading: () => const SizedBox(
                  height: 155,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
              loading: () => const SizedBox(
                height: 155,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ),

        // Stock par capacité section
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          sliver: SliverToBoxAdapter(
            child: const DashboardStockByCapacity(),
          ),
        ),

        // Performance chart (7 derniers jours)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          sliver: SliverToBoxAdapter(
            child: salesAsync.when(
              data: (sales) => expensesAsync.when(
                data: (expenses) => DashboardPerformanceSection(
                  sales: sales,
                  expenses: expenses,
                ),
                loading: () => const SizedBox(
                  height: 397,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
              loading: () => const SizedBox(
                height: 397,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ),

        // Performance par point de vente
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          sliver: SliverToBoxAdapter(
            child: salesAsync.when(
              data: (sales) => DashboardPosPerformanceSection(sales: sales),
              loading: () => const SizedBox(
                height: 262,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}
