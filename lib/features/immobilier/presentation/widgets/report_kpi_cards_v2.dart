import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/immobilier/application/providers.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/property.dart';
import 'dashboard_kpi_card_v2.dart';

/// KPI cards for immobilier reports module - style eau_minerale.
class ReportKpiCardsV2 extends ConsumerWidget {
  const ReportKpiCardsV2({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  final DateTime startDate;
  final DateTime endDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentsProvider);
    final expensesAsync = ref.watch(expensesProvider);
    final propertiesAsync = ref.watch(propertiesProvider);

    return paymentsAsync.when(
      data: (payments) {
        final periodPayments = payments.where((p) {
          return p.paymentDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
              p.paymentDate.isBefore(endDate.add(const Duration(days: 1))) &&
              p.status == PaymentStatus.paid;
        }).toList();

        final paymentsRevenue =
            periodPayments.fold(0, (sum, p) => sum + p.amount);

        return expensesAsync.when(
          data: (expenses) {
            final periodExpenses = expenses.where((e) {
              return e.expenseDate
                      .isAfter(startDate.subtract(const Duration(days: 1))) &&
                  e.expenseDate.isBefore(endDate.add(const Duration(days: 1)));
            }).toList();

            final expensesAmount =
                periodExpenses.fold(0, (sum, e) => sum + e.amount);
            final profit = paymentsRevenue - expensesAmount;

            return propertiesAsync.when(
              data: (properties) {
                final totalProperties = properties.length;
                final rentedProperties = properties
                    .where((p) => p.status == PropertyStatus.rented)
                    .length;
                final occupancyRate = totalProperties > 0
                    ? (rentedProperties / totalProperties * 100).round()
                    : 0;

                return _buildCards(
                  paymentsRevenue,
                  periodPayments.length,
                  expensesAmount,
                  periodExpenses.length,
                  profit,
                  occupancyRate,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCards(
    int paymentsRevenue,
    int paymentsCount,
    int expensesAmount,
    int expensesCount,
    int profit,
    int occupancyRate,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        return isWide
            ? Row(
                children: [
                  Expanded(
                    child: DashboardKpiCardV2(
                      label: 'Revenus Locatifs',
                      value: '${CurrencyFormatter.formatFCFA(paymentsRevenue)} FCFA',
                      subtitle: '$paymentsCount paiements',
                      icon: Icons.trending_up,
                      iconColor: Colors.blue,
                      backgroundColor: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DashboardKpiCardV2(
                      label: 'Dépenses',
                      value: '${CurrencyFormatter.formatFCFA(expensesAmount)} FCFA',
                      subtitle: '$expensesCount charges',
                      icon: Icons.receipt_long,
                      iconColor: Colors.red,
                      valueColor: Colors.red.shade700,
                      backgroundColor: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DashboardKpiCardV2(
                      label: 'Bénéfice Net',
                      value: '${CurrencyFormatter.formatFCFA(profit)} FCFA',
                      subtitle: profit >= 0 ? 'Profit' : 'Déficit',
                      icon: Icons.account_balance_wallet,
                      iconColor: profit >= 0 ? Colors.green : Colors.red,
                      valueColor: profit >= 0
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      backgroundColor: profit >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DashboardKpiCardV2(
                      label: "Taux d'Occupation",
                      value: '$occupancyRate%',
                      subtitle: 'propriétés louées',
                      icon: Icons.home,
                      iconColor: Colors.indigo,
                      backgroundColor: Colors.indigo,
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DashboardKpiCardV2(
                          label: 'Revenus Locatifs',
                          value: '${CurrencyFormatter.formatFCFA(paymentsRevenue)} FCFA',
                          subtitle: '$paymentsCount paiements',
                          icon: Icons.trending_up,
                          iconColor: Colors.blue,
                          backgroundColor: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DashboardKpiCardV2(
                          label: 'Dépenses',
                          value: '${CurrencyFormatter.formatFCFA(expensesAmount)} FCFA',
                          subtitle: '$expensesCount charges',
                          icon: Icons.receipt_long,
                          iconColor: Colors.red,
                          valueColor: Colors.red.shade700,
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DashboardKpiCardV2(
                          label: 'Bénéfice Net',
                          value: '${CurrencyFormatter.formatFCFA(profit)} FCFA',
                          subtitle: profit >= 0 ? 'Profit' : 'Déficit',
                          icon: Icons.account_balance_wallet,
                          iconColor: profit >= 0 ? Colors.green : Colors.red,
                          valueColor: profit >= 0
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                          backgroundColor:
                              profit >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DashboardKpiCardV2(
                          label: "Taux d'Occupation",
                          value: '$occupancyRate%',
                          subtitle: 'propriétés louées',
                          icon: Icons.home,
                          iconColor: Colors.indigo,
                          backgroundColor: Colors.indigo,
                        ),
                      ),
                    ],
                  ),
                ],
              );
      },
    );
  }
}
