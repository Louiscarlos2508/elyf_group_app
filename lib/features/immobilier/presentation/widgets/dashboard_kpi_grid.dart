import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/immobilier/application/providers.dart';
import '../../domain/entities/contract.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/tenant.dart';
import 'immobilier_kpi_card.dart';

/// Widget pour afficher la grille de KPIs du dashboard.
class DashboardKpiGrid extends ConsumerWidget {
  const DashboardKpiGrid({
    super.key,
    required this.properties,
    required this.tenants,
    required this.contracts,
    required this.payments,
    required this.expenses,
  });

  final List<Property> properties;
  final List<Tenant> tenants;
  final List<Contract> contracts;
  final List<Payment> payments;
  final List<PropertyExpense> expenses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Utiliser le service de calcul pour extraire la logique métier
    final calculationService = ref.read(
      immobilierDashboardCalculationServiceProvider,
    );
    final metrics = calculationService.calculateMonthlyMetrics(
      properties: properties,
      tenants: tenants,
      contracts: contracts,
      payments: payments,
      expenses: expenses,
    );

    final cards = [
      ImmobilierKpiCard(
        label: 'Propriétés',
        value: metrics.totalProperties.toString(),
        subtitle: '${metrics.rentedProperties} louées',
        icon: Icons.home,
        color: Colors.blue,
      ),
      ImmobilierKpiCard(
        label: 'Disponibles',
        value: metrics.availableProperties.toString(),
        subtitle: 'unités vacantes',
        icon: Icons.check_circle,
        color: Colors.green,
      ),
      ImmobilierKpiCard(
        label: 'Locataires',
        value: metrics.totalTenants.toString(),
        subtitle: 'personnes inscrites',
        icon: Icons.people,
        color: Colors.purple,
      ),
      ImmobilierKpiCard(
        label: 'Contrats actifs',
        value: metrics.activeContractsCount.toString(),
        subtitle: 'engagements en cours',
        icon: Icons.description,
        color: Colors.orange,
      ),
      ImmobilierKpiCard(
        label: 'Revenus du mois',
        value: CurrencyFormatter.formatFCFA(metrics.monthRevenue),
        subtitle: '${metrics.monthPaymentsCount} encaissements',
        icon: Icons.trending_up,
        color: Colors.green,
      ),
      ImmobilierKpiCard(
        label: 'Dépenses du mois',
        value: CurrencyFormatter.formatFCFA(metrics.monthExpensesTotal),
        subtitle: 'charges payées',
        icon: Icons.trending_down,
        color: Colors.red,
      ),
      ImmobilierKpiCard(
        label: 'Résultat net',
        value: CurrencyFormatter.formatFCFA(metrics.netRevenue),
        subtitle: metrics.netRevenue >= 0 ? 'bénéfice mensuel' : 'perte mensuelle',
        icon: Icons.account_balance_wallet,
        color: metrics.netRevenue >= 0 ? Colors.green : Colors.red,
      ),
      ImmobilierKpiCard(
        label: 'Taux d\'occupation',
        value: '${metrics.occupancyRate.toStringAsFixed(0)}%',
        subtitle: 'rendement spatial',
        icon: Icons.percent,
        color: Colors.indigo,
      ),
      ImmobilierKpiCard(
        label: 'Loyers mensuels',
        value: CurrencyFormatter.formatFCFA(metrics.totalMonthlyRent),
        subtitle: 'potentiel théorique',
        icon: Icons.attach_money,
        color: Colors.teal,
      ),
    ];

    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isWide = screenWidth > 600;

        if (isWide) {
          return Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 16),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: cards[6]),
                    const SizedBox(width: 16),
                    Expanded(child: cards[7]),
                    const SizedBox(width: 16),
                    Expanded(child: cards[8]),
                  ],
                ),
              ),
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 12),
                Expanded(child: cards[1]),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cards[2]),
                const SizedBox(width: 12),
                Expanded(child: cards[3]),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cards[4]),
                const SizedBox(width: 12),
                Expanded(child: cards[5]),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cards[6]),
                const SizedBox(width: 12),
                Expanded(child: cards[7]),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Expanded(child: cards[8])],
            ),
          ],
        );
      },
    );
  }
}
