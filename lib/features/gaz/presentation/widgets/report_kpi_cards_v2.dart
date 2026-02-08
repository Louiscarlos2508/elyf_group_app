import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/report_data.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';

/// KPI cards for gaz reports module - style eau_minerale.
class GazReportKpiCardsV2 extends ConsumerWidget {
  const GazReportKpiCardsV2({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  final DateTime startDate;
  final DateTime endDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportDataAsync = ref.watch(
      gazReportDataProvider((
        period: GazReportPeriod.custom,
        startDate: startDate,
        endDate: endDate,
      )),
    );

    return reportDataAsync.when(
      data: (data) {
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 600) {
              return Row(
                children: [
                  Expanded(
                    child: ElyfStatsCard(
                      label: "Chiffre d'Affaires",
                      value: CurrencyFormatter.formatDouble(data.salesRevenue),
                      subtitle: '${data.salesCount} ventes',
                      icon: Icons.trending_up,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElyfStatsCard(
                      label: 'Dépenses',
                      value: CurrencyFormatter.formatDouble(data.expensesAmount),
                      subtitle: '${data.expensesCount} charges',
                      icon: Icons.receipt_long,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElyfStatsCard(
                      label: 'Bénéfice Net',
                      value: CurrencyFormatter.formatDouble(data.profit),
                      subtitle: data.profit >= 0 ? 'Profit' : 'Déficit',
                      icon: Icons.account_balance_wallet,
                      color: data.profit >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                ElyfStatsCard(
                  label: "Chiffre d'Affaires",
                  value: CurrencyFormatter.formatDouble(data.salesRevenue),
                  subtitle: '${data.salesCount} ventes',
                  icon: Icons.trending_up,
                  color: Colors.blue,
                ),
                const SizedBox(height: AppSpacing.md),
                ElyfStatsCard(
                  label: 'Dépenses',
                  value: CurrencyFormatter.formatDouble(data.expensesAmount),
                  subtitle: '${data.expensesCount} charges',
                  icon: Icons.receipt_long,
                  color: Colors.red,
                ),
                const SizedBox(height: AppSpacing.md),
                ElyfStatsCard(
                  label: 'Bénéfice Net',
                  value: CurrencyFormatter.formatDouble(data.profit),
                  subtitle: data.profit >= 0 ? 'Profit' : 'Déficit',
                  icon: Icons.account_balance_wallet,
                  color: data.profit >= 0 ? Colors.green : Colors.red,
                ),
              ],
            );
          },
        );
      },
      loading: () => const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
