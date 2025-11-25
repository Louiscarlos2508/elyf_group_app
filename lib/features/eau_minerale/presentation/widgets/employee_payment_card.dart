import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/employee.dart';
import '../../domain/entities/salary_payment.dart';
import 'form_dialog.dart';
import 'monthly_salary_payment_form.dart';

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
    final formKey = GlobalKey<MonthlySalaryPaymentFormState>();
    showDialog(
      context: context,
      builder: (context) => FormDialog(
        title: 'Paiement de Salaire Mensuel',
        child: MonthlySalaryPaymentForm(key: formKey, employee: employee),
        onSave: () async {
          final state = formKey.currentState;
          if (state != null) {
            await state.submit();
          }
        },
        saveLabel: 'Enregistrer le Paiement',
      ),
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        ) + ' FCFA';
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
          ListTile(
            leading: CircleAvatar(
              child: Text(employee.name[0].toUpperCase()),
            ),
            title: Text(employee.name),
            subtitle: employee.position != null
                ? Text('${employee.position} • ${_formatCurrency(employee.monthlySalary)}/mois')
                : Text('${_formatCurrency(employee.monthlySalary)}/mois'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasCurrentMonthPayment)
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
                const SizedBox(width: 8),
                IntrinsicWidth(
                  child: OutlinedButton.icon(
                    onPressed: () => _showPaymentForm(context, ref),
                    icon: const Icon(Icons.payment, size: 18),
                    label: const Text('Payer'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
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
                  Text(
                    'Derniers paiements',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...monthlyPayments.take(3).map((payment) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            payment.period,
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            _formatCurrency(payment.amount),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

