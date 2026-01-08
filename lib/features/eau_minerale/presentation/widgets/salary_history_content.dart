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

        if (allPayments.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.history_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun paiement enregistré',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Historique des Paiements',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tous les paiements de salaires et de production',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              ...allPayments.map((payment) => SalaryHistoryItem(
                    payment: payment,
                  )),
            ],
          ),
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
      items.add(SalaryHistoryItemData(
        date: payment.date,
        amount: payment.amount,
        type: SalaryPaymentType.monthly,
        label: payment.employeeName,
        period: payment.period,
      ));
    }

    for (final payment in productionPayments) {
      items.add(SalaryHistoryItemData(
        date: payment.paymentDate,
        amount: payment.totalAmount,
        type: SalaryPaymentType.production,
        label: 'Paiement Production',
        period: payment.period,
      ));
    }

    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }
}

