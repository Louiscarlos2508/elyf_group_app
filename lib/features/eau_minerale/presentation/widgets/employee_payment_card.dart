import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/utils/currency_formatter.dart';
import '../../application/providers.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/salary_payment.dart';
import '../../../../../shared/presentation/widgets/form_dialog.dart';
import 'monthly_salary_payment_form.dart';
import 'salary_receipt_dialog.dart';

/// Card widget displaying employee info and payment history.
class EmployeePaymentCard extends ConsumerWidget {
  const EmployeePaymentCard({
    super.key,
    required this.employee,
    required this.monthlyPayments,
  });

  final Employee employee;
  final List<SalaryPayment> monthlyPayments;

  void _showPaymentForm(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.read(salaryStateProvider);
    final existingPayments = stateAsync.maybeWhen(
      data: (data) => data.monthlySalaryPayments
          .where((p) => p.employeeId == employee.id)
          .toList(),
      orElse: () => <SalaryPayment>[],
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        final formKey = GlobalKey<MonthlySalaryPaymentFormState>();
        return FormDialog(
          title: 'Paiement de Salaire Mensuel',
          onSave: () async {
            final formState = formKey.currentState;
            if (formState != null) {
              await formState.submit();
            }
          },
          saveLabel: 'Enregistrer le Paiement',
          child: MonthlySalaryPaymentForm(
            key: formKey,
            employee: employee,
            existingPayments: existingPayments,
          ),
        );
      },
    );
  }

  void _showReceipt(BuildContext context, SalaryPayment payment) {
    showDialog(
      context: context,
      builder: (context) => SalaryReceiptDialog(
        employee: employee,
        payment: payment,
      ),
    );
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentMonth = DateTime.now().month;
    final currentYear = DateTime.now().year;
    final hasCurrentMonthPayment = monthlyPayments.any((p) =>
        p.date.month == currentMonth && p.date.year == currentYear);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      child: Text(employee.name[0].toUpperCase()),
                    ),
                    const SizedBox(width: 12),
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
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (hasCurrentMonthPayment) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Payé',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            employee.position != null
                                ? '${employee.position} • ${CurrencyFormatter.format(employee.monthlySalary)}/mois'
                                : '${CurrencyFormatter.format(employee.monthlySalary)}/mois',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showPaymentForm(context, ref),
                    icon: const Icon(Icons.payment, size: 18),
                    label: const Text('Enregistrer un paiement'),
                  ),
                ),
              ],
            ),
          ),
          if (monthlyPayments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Derniers paiements',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (monthlyPayments.length > 3)
                        TextButton(
                          onPressed: () {
                            // TODO: Navigate to full payment history
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 32),
                          ),
                          child: Text(
                            'Voir tout (${monthlyPayments.length})',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...monthlyPayments
                      .take(3)
                      .map((payment) => _PaymentHistoryItem(
                            payment: payment,
                            onTap: () => _showReceipt(context, payment),
                            theme: theme,
                          )),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Widget for displaying a single payment history item.
class _PaymentHistoryItem extends StatelessWidget {
  const _PaymentHistoryItem({
    required this.payment,
    required this.onTap,
    required this.theme,
  });

  final SalaryPayment payment;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment.period,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (payment.notes != null && payment.notes!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            payment.notes!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (payment.aSignature) ...[
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'Signature enregistrée',
                      child: Icon(
                        Icons.check_circle,
                        size: 18,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              CurrencyFormatter.format(payment.amount),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

