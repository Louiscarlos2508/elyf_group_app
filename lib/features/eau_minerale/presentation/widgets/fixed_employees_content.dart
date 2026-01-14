import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import 'employee_payment_card.dart';

/// Content widget for fixed employees tab.
class FixedEmployeesContent extends ConsumerWidget {
  const FixedEmployeesContent({super.key, required this.onNewEmployee});

  final VoidCallback onNewEmployee;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(salaryStateProvider);

    return state.when(
      data: (data) {
        final employees = data.fixedEmployees;

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
                                'Employés à Salaire Mensuel',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Gérez vos employés permanents et enregistrez leurs salaires mensuels',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IntrinsicWidth(
                          child: FilledButton.icon(
                            onPressed: onNewEmployee,
                            icon: const Icon(Icons.add),
                            label: const Text('Nouvel Employé'),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Employés à Salaire Mensuel',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Gérez vos employés permanents et enregistrez leurs salaires mensuels',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: onNewEmployee,
                            icon: const Icon(Icons.add),
                            label: const Text('Nouvel Employé'),
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
              if (employees.isEmpty) ...[
                const SizedBox(height: 48),
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun employé fixe enregistré',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cliquez sur "Nouvel Employé" pour commencer',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 24),
                ...employees.map(
                  (employee) => EmployeePaymentCard(
                    employee: employee,
                    monthlyPayments: (data.monthlySalaryPayments)
                        .where((p) => p.employeeId == employee.id)
                        .toList(),
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
