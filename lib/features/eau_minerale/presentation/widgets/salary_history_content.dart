import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/production_payment.dart';
import '../../domain/entities/salary_payment.dart';
import 'salary_history_item.dart';
import 'salary_history_item_data.dart';

/// Content widget for salary history tab.
class SalaryHistoryContent extends ConsumerWidget {
  const SalaryHistoryContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(salaryStateProvider);

    return state.when(
      data: (data) {
        final allPayments = _combinePayments(
          data.monthlySalaryPayments,
          data.productionPayments,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Historique Global',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Tous les flux de salaires et de production',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (allPayments.isEmpty)
              _EmptyHistoryPlaceholder()
            else
              ...allPayments.map(
                (payment) => SalaryHistoryItem(payment: payment),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  List<SalaryHistoryItemData> _combinePayments(
    List<SalaryPayment> monthlyPayments,
    List<ProductionPayment> productionPayments,
  ) {
    final items = <SalaryHistoryItemData>[];

    for (final payment in monthlyPayments) {
      items.add(
        SalaryHistoryItemData(
          date: payment.date,
          amount: payment.amount,
          type: SalaryPaymentType.monthly,
          label: payment.employeeName,
          period: payment.period,
          originalPayment: payment,
        ),
      );
    }

    for (final payment in productionPayments) {
      String label;
      if (payment.persons.isEmpty) {
        label = 'Paiement Production';
      } else if (payment.persons.length == 1) {
        label = payment.persons.first.name;
      } else {
        final first = payment.persons.first.name;
        final count = payment.persons.length - 1;
        label = '$first + $count autre(s)';
      }

      items.add(
        SalaryHistoryItemData(
          date: payment.paymentDate,
          amount: payment.totalAmount,
          type: SalaryPaymentType.production,
          label: label,
          period: payment.period,
          originalPayment: payment,
        ),
      );
    }

    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }
}

class _EmptyHistoryPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(
              Icons.history_rounded,
              size: 64,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun historique disponible',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
