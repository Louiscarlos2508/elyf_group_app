import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/production_payment.dart';
import 'weekly_salary_calculator.dart';

/// Content widget for production payments tab.
class ProductionPaymentsContent extends ConsumerWidget {
  const ProductionPaymentsContent({super.key, required this.onNewPayment});

  final VoidCallback onNewPayment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(salaryStateProvider);

    return state.when(
      data: (data) {
        final payments = data.productionPayments;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;

                if (isWide) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Paiements Production / Hebdomadaires',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Enregistrez les paiements pour les productions de la semaine (prestataires, ouvriers occasionnels)',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IntrinsicWidth(
                        child: FilledButton.icon(
                          onPressed: onNewPayment,
                          icon: const Icon(Icons.add),
                          label: const Text('Nouveau Paiement'),
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paiements Production / Hebdomadaires',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Enregistrez les paiements pour les productions de la semaine (prestataires, ouvriers occasionnels)',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: onNewPayment,
                          icon: const Icon(Icons.add),
                          label: const Text('Nouveau Paiement'),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 24),
            // Calculateur de salaires hebdomadaires (toujours visible)
            const WeeklySalaryCalculator(),
            if (payments.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
              Text(
                'Historique des paiements',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...payments.map((payment) => _PaymentCard(payment: payment)),
            ] else ...[
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.history,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun paiement enregistré',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment});

  final ProductionPayment payment;

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSignature = payment.signature != null && payment.signature!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        onTap: hasSignature
            ? () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Signature du bénéficiaire'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.colorScheme.outlineVariant),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.memory(
                            payment.signature!,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Fermer'),
                      ),
                    ],
                  ),
                );
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.factory_outlined,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment.period,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(payment.paymentDate),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasSignature)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified,
                        color: Colors.green,
                        size: 16,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(
                height: 1,
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${payment.persons.length} personne${payment.persons.length > 1 ? 's' : ''}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      CurrencyFormatter.formatFCFA(payment.totalAmount),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
