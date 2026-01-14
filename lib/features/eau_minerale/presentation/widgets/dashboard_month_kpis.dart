import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/controllers/clients_controller.dart';
import '../../application/controllers/finances_controller.dart';
import '../../application/controllers/sales_controller.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/production_session.dart';
import 'dashboard_kpi_card.dart';

/// Section displaying monthly KPIs with production sessions data.
class DashboardMonthKpis extends ConsumerWidget {
  const DashboardMonthKpis({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesState = ref.watch(salesStateProvider);
    final clientsState = ref.watch(clientsStateProvider);
    final financesState = ref.watch(financesStateProvider);
    final productionState = ref.watch(productionSessionsStateProvider);

    return salesState.when(
      data: (sales) => clientsState.when(
        data: (clients) => financesState.when(
          data: (finances) => productionState.when(
            data: (sessions) =>
                _buildKpis(context, sales, clients, finances, sessions, ref),
            loading: () => _buildLoadingState(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          loading: () => _buildLoadingState(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        loading: () => _buildLoadingState(),
        error: (_, __) => const SizedBox.shrink(),
      ),
      loading: () => _buildLoadingState(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildLoadingState() {
    return const SizedBox(
      height: 200,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildKpis(
    BuildContext context,
    SalesState sales,
    ClientsState clients,
    FinancesState finances,
    List<ProductionSession> sessions,
    WidgetRef ref,
  ) {
    // Utiliser le service de calcul pour extraire la logique métier
    final calculationService = ref.read(dashboardCalculationServiceProvider);
    final now = DateTime.now();
    final monthStart = calculationService.getMonthStart(now);

    // Ventes du mois
    final monthRevenue = calculationService.calculateMonthlyRevenue(
      sales.sales,
      monthStart,
    );
    final monthCollections = calculationService.calculateMonthlyCollections(
      sales.sales,
      monthStart,
    );

    // Production du mois
    final monthSessions = sessions
        .where((s) => s.date.isAfter(monthStart))
        .toList();
    final monthProduction = monthSessions.fold<int>(
      0,
      (sum, s) => sum + s.quantiteProduite,
    );

    // Dépenses du mois
    final monthExpenses = calculationService
        .calculateMonthlyExpensesFromRecords(finances.expenses, monthStart);

    // Résultat net
    final monthResult = calculationService.calculateMonthlyResult(
      monthCollections,
      monthExpenses,
    );
    final monthSales = sales.sales
        .where((s) => s.date.isAfter(monthStart))
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;

        final cards = [
          DashboardKpiCard(
            label: 'Chiffre d\'Affaires',
            value: CurrencyFormatter.formatFCFA(monthRevenue),
            subtitle: '${monthSales.length} ventes',
            icon: Icons.trending_up,
            iconColor: Colors.blue,
            backgroundColor: Colors.blue,
          ),
          DashboardKpiCard(
            label: 'Production',
            value: '$monthProduction sachets',
            subtitle: '${monthSessions.length} sessions',
            icon: Icons.factory,
            iconColor: Colors.purple,
            backgroundColor: Colors.purple,
          ),
          DashboardKpiCard(
            label: 'Dépenses',
            value: CurrencyFormatter.formatFCFA(monthExpenses),
            subtitle:
                '${finances.expenses.where((e) => e.date.isAfter(monthStart)).length} transactions',
            icon: Icons.receipt_long,
            iconColor: Colors.red,
            backgroundColor: Colors.red,
          ),
          DashboardKpiCard(
            label: 'Résultat Net',
            value: CurrencyFormatter.formatFCFA(monthResult),
            subtitle: monthResult >= 0 ? 'Bénéfice' : 'Déficit',
            icon: Icons.account_balance_wallet,
            iconColor: monthResult >= 0 ? Colors.green : Colors.red,
            valueColor: monthResult >= 0
                ? Colors.green.shade700
                : Colors.red.shade700,
            backgroundColor: monthResult >= 0 ? Colors.green : Colors.red,
          ),
        ];

        if (isWide) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 16),
                Expanded(child: cards[1]),
                const SizedBox(width: 16),
                Expanded(child: cards[2]),
                const SizedBox(width: 16),
                Expanded(child: cards[3]),
              ],
            ),
          );
        }

        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 16),
                Expanded(child: cards[1]),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cards[2]),
                const SizedBox(width: 16),
                Expanded(child: cards[3]),
              ],
            ),
          ],
        );
      },
    );
  }
}
