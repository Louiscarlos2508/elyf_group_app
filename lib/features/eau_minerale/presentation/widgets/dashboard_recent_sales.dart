import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sales_report_table.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import 'package:elyf_groupe_app/shared/presentation/widgets/loading_indicator.dart';

class DashboardRecentSales extends ConsumerWidget {
  const DashboardRecentSales({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final salesStateAsync = ref.watch(salesStateProvider);

    return salesStateAsync.when(
      data: (salesState) {
        final recentSales = salesState.sales.take(5).toList();
        
        if (recentSales.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ventes Récentes',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to activity or all sales
                    },
                    child: const Text('Voir tout'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SalesReportTable(sales: recentSales),
            ),
          ],
        );
      },
      loading: () => const LoadingIndicator(),
      error: (error, _) => const SizedBox.shrink(),
    );
  }
}
