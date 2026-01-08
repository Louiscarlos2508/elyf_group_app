import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/immobilier/application/providers.dart';
import '../../domain/entities/contract.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/property.dart';
import 'enhanced_kpi_card.dart';
import 'reports_helpers.dart';

/// Widget pour afficher la grille de KPIs des rapports.
class ReportsKpiGrid extends ConsumerWidget {
  const ReportsKpiGrid({
    super.key,
    required this.properties,
    required this.contracts,
    required this.payments,
    required this.expenses,
    required this.periodPayments,
    required this.periodExpenses,
  });

  final List<Property> properties;
  final List<Contract> contracts;
  final List<Payment> payments;
  final List<PropertyExpense> expenses;
  final List<Payment> periodPayments;
  final List<PropertyExpense> periodExpenses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Utiliser le service de calcul pour extraire la logique métier
    final reportService = ref.read(immobilierReportCalculationServiceProvider);
    final metrics = reportService.calculateReportMetrics(
      properties: properties,
      contracts: contracts,
      periodPayments: periodPayments,
      periodExpenses: periodExpenses,
    );

    final cards = [
      EnhancedKpiCard(
        label: 'Revenus',
        value: ReportsHelpers.formatCurrency(metrics.totalRevenue),
        icon: Icons.trending_up,
        color: Colors.green,
      ),
      EnhancedKpiCard(
        label: 'Dépenses',
        value: ReportsHelpers.formatCurrency(metrics.totalExpenses),
        icon: Icons.trending_down,
        color: Colors.red,
      ),
      EnhancedKpiCard(
        label: 'Résultat net',
        value: ReportsHelpers.formatCurrency(metrics.netRevenue),
        icon: Icons.account_balance_wallet,
        color: metrics.isProfit ? Colors.green : Colors.red,
      ),
      EnhancedKpiCard(
        label: 'Paiements',
        value: metrics.paidPaymentsCount.toString(),
        icon: Icons.payment,
        color: Colors.blue,
      ),
      EnhancedKpiCard(
        label: 'Taux d\'occupation',
        value: '${metrics.occupancyRate.toStringAsFixed(0)}%',
        icon: Icons.percent,
        color: Colors.purple,
      ),
      EnhancedKpiCard(
        label: 'Contrats actifs',
        value: metrics.activeContractsCount.toString(),
        icon: Icons.description,
        color: Colors.orange,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        if (isWide) {
          return Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: 16),
                    Expanded(child: cards[1]),
                    const SizedBox(width: 16),
                    Expanded(child: cards[2]),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: cards[3]),
                    const SizedBox(width: 16),
                    Expanded(child: cards[4]),
                    const SizedBox(width: 16),
                    Expanded(child: cards[5]),
                  ],
                ),
              ),
            ],
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
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cards[4]),
                const SizedBox(width: 16),
                Expanded(child: cards[5]),
              ],
            ),
          ],
        );
      },
    );
  }
}

