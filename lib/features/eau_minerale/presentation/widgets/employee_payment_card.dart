import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/salary_payment.dart';
import 'monthly_salary_payment_form.dart';
import '../../application/services/payment_receipt_generator.dart';

/// Card widget displaying employee info and payment history.
class EmployeePaymentCard extends ConsumerWidget {
  const EmployeePaymentCard({
    super.key,
    required this.employee,
    required this.monthlyPayments,
    this.onEdit,
  });

  final Employee employee;
  final List<SalaryPayment> monthlyPayments;
  final VoidCallback? onEdit;

  void _showPaymentForm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => MonthlySalaryPaymentForm(
        employee: employee,
        existingPayments: monthlyPayments,
      ),
    );
  }

  Future<void> _showReceipt(BuildContext context, SalaryPayment payment) async {
    try {
      await PaymentReceiptGenerator.generateMonthlyReceipt(payment);
    } catch (e) {
      if (context.mounted) {
        NotificationService.showError(context, 'Erreur lors de la génération du reçu: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currencyFormat = CurrencyFormatter.formatFCFA;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  employee.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (onEdit != null)
                                IconButton(
                                  onPressed: onEdit,
                                  icon: const Icon(Icons.edit_rounded, size: 18),
                                  style: IconButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                    foregroundColor: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                          if (employee.position != null)
                            Text(
                              employee.position!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Salaire: ${currencyFormat(employee.monthlySalary)}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Check if payment already exists for current month
                Builder(
                  builder: (context) {
                    final now = DateTime.now();
                    final hasPaymentThisMonth = monthlyPayments.any(
                      (p) => p.date.month == now.month && p.date.year == now.year,
                    );

                    if (hasPaymentThisMonth) {
                      // Show info message instead of button
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Salaire déjà payé ce mois',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Show payment button if no payment this month
                    return SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _showPaymentForm(context, ref),
                        icon: const Icon(Icons.payments_rounded, size: 18),
                        label: const Text('Payer Salaire'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          if (monthlyPayments.isNotEmpty) ...[
            Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            _PaymentHistoryPreview(
              payments: monthlyPayments,
              onPaymentTap: (payment) => _showReceipt(context, payment),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentHistoryPreview extends StatelessWidget {
  const _PaymentHistoryPreview({
    required this.payments,
    required this.onPaymentTap,
  });

  final List<SalaryPayment> payments;
  final Function(SalaryPayment) onPaymentTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayPayments = payments.take(2).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'HISTORIQUE RÉCENT',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              if (payments.length > 2)
                Text(
                  '+${payments.length - 2} autres',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...displayPayments.map((payment) => _PaymentRow(
                payment: payment,
                onTap: () => onPaymentTap(payment),
              )),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment, required this.onTap});
  final SalaryPayment payment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                payment.period,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Text(
              CurrencyFormatter.formatFCFA(payment.amount),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: theme.colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}
