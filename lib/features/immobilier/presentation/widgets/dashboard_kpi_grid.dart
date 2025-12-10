import 'package:flutter/material.dart';

import '../../domain/entities/contract.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/tenant.dart';
import 'enhanced_kpi_card.dart';

/// Widget pour afficher la grille de KPIs du dashboard.
class DashboardKpiGrid extends StatelessWidget {
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

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        ) + ' F';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    // Calculs des KPIs
    final totalProperties = properties.length;
    final availableProperties = properties
        .where((p) => p.status == PropertyStatus.available)
        .length;
    final rentedProperties = properties
        .where((p) => p.status == PropertyStatus.rented)
        .length;

    final totalTenants = tenants.length;

    final activeContracts = contracts
        .where((c) => c.status == ContractStatus.active)
        .toList();
    final activeContractsCount = activeContracts.length;

    // Loyers mensuels totaux (contrats actifs)
    final totalMonthlyRent = activeContracts.fold<int>(
      0,
      (sum, c) => sum + c.monthlyRent,
    );

    // Paiements du mois
    final monthPayments = payments.where((p) {
      return p.paymentDate.isAfter(monthStart.subtract(const Duration(days: 1))) &&
          p.status == PaymentStatus.paid;
    }).toList();
    final monthRevenue = monthPayments.fold<int>(
      0,
      (sum, p) => sum + p.amount,
    );

    // Dépenses du mois
    final monthExpenses = expenses.where((e) {
      return e.expenseDate.isAfter(monthStart.subtract(const Duration(days: 1)));
    }).toList();
    final monthExpensesTotal = monthExpenses.fold<int>(
      0,
      (sum, e) => sum + e.amount,
    );

    final netRevenue = monthRevenue - monthExpensesTotal;

    final occupancyRate = totalProperties > 0
        ? (rentedProperties / totalProperties) * 100
        : 0.0;

    final cards = [
      EnhancedKpiCard(
        label: 'Propriétés',
        value: totalProperties.toString(),
        icon: Icons.home,
        color: Colors.blue,
      ),
      EnhancedKpiCard(
        label: 'Disponibles',
        value: availableProperties.toString(),
        icon: Icons.check_circle,
        color: Colors.green,
      ),
      EnhancedKpiCard(
        label: 'Locataires',
        value: totalTenants.toString(),
        icon: Icons.people,
        color: Colors.purple,
      ),
      EnhancedKpiCard(
        label: 'Contrats actifs',
        value: activeContractsCount.toString(),
        icon: Icons.description,
        color: Colors.orange,
      ),
      EnhancedKpiCard(
        label: 'Revenus du mois',
        value: _formatCurrency(monthRevenue),
        icon: Icons.trending_up,
        color: Colors.green,
      ),
      EnhancedKpiCard(
        label: 'Dépenses du mois',
        value: _formatCurrency(monthExpensesTotal),
        icon: Icons.trending_down,
        color: Colors.red,
      ),
      EnhancedKpiCard(
        label: 'Résultat net',
        value: _formatCurrency(netRevenue),
        icon: Icons.account_balance_wallet,
        color: netRevenue >= 0 ? Colors.green : Colors.red,
      ),
      EnhancedKpiCard(
        label: 'Taux d\'occupation',
        value: '${occupancyRate.toStringAsFixed(0)}%',
        icon: Icons.percent,
        color: Colors.indigo,
      ),
      EnhancedKpiCard(
        label: 'Loyers mensuels',
        value: _formatCurrency(totalMonthlyRent),
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
              children: [
                Expanded(child: cards[8]),
              ],
            ),
          ],
        );
      },
    );
  }
}

