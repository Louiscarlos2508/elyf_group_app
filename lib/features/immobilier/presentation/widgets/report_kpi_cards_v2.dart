import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/immobilier/application/providers.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/property.dart';
import 'immobilier_kpi_card.dart';

/// KPI cards for immobilier reports module - style eau_minerale.
class ReportKpiCardsV2 extends ConsumerWidget {
  const ReportKpiCardsV2({
    super.key,
    required this.startDate,
    this.endDate,
  });

  final DateTime startDate;
  final DateTime? endDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentsWithRelationsProvider);
    final expensesAsync = ref.watch(expensesProvider);
    final propertiesAsync = ref.watch(propertiesProvider);

    return paymentsAsync.when(
      data: (payments) {
        final periodPayments = payments.where((p) {
          return p.paymentDate.isAfter(
                startDate.subtract(const Duration(days: 1)),
              ) &&
              (endDate == null ||
                  p.paymentDate
                      .isBefore(endDate!.add(const Duration(days: 1)))) &&
              p.status == PaymentStatus.paid;
        }).toList();

        final paymentsRevenue = periodPayments.fold(
          0,
          (sum, p) => sum + p.amount,
        );

        return expensesAsync.when(
          data: (expenses) {
            final periodExpenses = expenses.where((e) {
              return e.expenseDate.isAfter(
                    startDate.subtract(const Duration(days: 1)),
                  ) &&
                  (endDate == null ||
                      e.expenseDate
                          .isBefore(endDate!.add(const Duration(days: 1))));
            }).toList();

            final expensesAmount = periodExpenses.fold(
              0,
              (sum, e) => sum + e.amount,
            );
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

        final revenueCard = ImmobilierKpiCard(
          label: 'Revenus Locatifs',
          value: '${CurrencyFormatter.formatFCFA(paymentsRevenue)} FCFA',
          subtitle: '$paymentsCount paiements',
          icon: Icons.trending_up,
          color: Colors.blue,
        );

        final expensesCard = ImmobilierKpiCard(
          label: 'Dépenses',
          value: '${CurrencyFormatter.formatFCFA(expensesAmount)} FCFA',
          subtitle: '$expensesCount charges',
          icon: Icons.receipt_long,
          color: Colors.red,
        );

        final profitCard = ImmobilierKpiCard(
          label: 'Bénéfice Net',
          value: '${CurrencyFormatter.formatFCFA(profit)} FCFA',
          subtitle: profit >= 0 ? 'Profit' : 'Déficit',
          icon: Icons.account_balance_wallet,
          color: profit >= 0 ? Colors.green : Colors.red,
        );

        final occupancyCard = ImmobilierKpiCard(
          label: "Taux d'Occupation",
          value: '$occupancyRate%',
          subtitle: 'propriétés louées',
          icon: Icons.home,
          color: Colors.indigo,
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(child: revenueCard),
              const SizedBox(width: 16),
              Expanded(child: expensesCard),
              const SizedBox(width: 16),
              Expanded(child: profitCard),
              const SizedBox(width: 16),
              Expanded(child: occupancyCard),
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(child: revenueCard),
                const SizedBox(width: 16),
                Expanded(child: expensesCard),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: profitCard),
                const SizedBox(width: 16),
                Expanded(child: occupancyCard),
              ],
            ),
          ],
        );
      },
    );
  }
}
