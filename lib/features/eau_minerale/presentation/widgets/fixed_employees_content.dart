import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/daily_worker.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/employee.dart';
import 'employee_payment_card.dart';
import 'fixed_employee_form.dart';
import 'daily_worker_form_dialog.dart';

/// Content widget for managing employees (Fixed and Daily).
class FixedEmployeesContent extends ConsumerWidget {
  const FixedEmployeesContent({super.key, required this.onNewEmployee});

  final VoidCallback onNewEmployee;

  void _showEditEmployeeDialog(BuildContext context, WidgetRef ref, Employee employee) {
    final formKey = GlobalKey<FixedEmployeeFormState>();
    showDialog(
      context: context,
      builder: (context) => FormDialog(
        title: 'Modifier Employé Fixe',
        child: FixedEmployeeForm(key: formKey, employee: employee),
        onSave: () async {
          final state = formKey.currentState;
          if (state != null) {
            await state.submit();
          }
        },
      ),
    );
  }

  void _showDailyWorkerForm(BuildContext context, [DailyWorker? worker]) {
    showDialog(
      context: context,
      builder: (context) => DailyWorkerFormDialog(worker: worker),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salaryState = ref.watch(salaryStateProvider);
    final dailyWorkersState = ref.watch(allDailyWorkersProvider);

    return salaryState.when(
      data: (data) {
        final fixedEmployees = data.fixedEmployees;

        return dailyWorkersState.when(
          data: (dailyWorkers) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Personnel Fixe ---
                _SectionHeader(
                  title: 'Personnel Fixe',
                  count: fixedEmployees.length,
                  onAdd: onNewEmployee,
                  icon: Icons.badge_rounded,
                ),
                if (fixedEmployees.isEmpty)
                  _EmptySectionPlaceholder(
                    label: 'Aucun employé fixe',
                    onAdd: onNewEmployee,
                  )
                else
                  ...fixedEmployees.map(
                    (employee) => EmployeePaymentCard(
                      employee: employee,
                      monthlyPayments: (data.monthlySalaryPayments)
                          .where((p) => p.employeeId == employee.id)
                          .toList(),
                      onEdit: () => _showEditEmployeeDialog(context, ref, employee),
                    ),
                  ),

                const SizedBox(height: 32),

                // --- Personnel Journalier ---
                _SectionHeader(
                  title: 'Personnel Journalier',
                  count: dailyWorkers.length,
                  onAdd: () => _showDailyWorkerForm(context),
                  icon: Icons.engineering_rounded,
                ),
                if (dailyWorkers.isEmpty)
                  _EmptySectionPlaceholder(
                    label: 'Aucun ouvrier journalier',
                    onAdd: () => _showDailyWorkerForm(context),
                  )
                else
                  ...dailyWorkers.map(
                    (worker) => _DailyWorkerCard(
                      worker: worker,
                      onEdit: () => _showDailyWorkerForm(context, worker),
                    ),
                  ),
                  
                const SizedBox(height: 80), // Bottom padding
              ],
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
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
    required this.onAdd,
    required this.icon,
  });

  final String title;
  final int count;
  final VoidCallback onAdd;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  '$count actif(s)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Ajouter'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyWorkerCard extends StatelessWidget {
  const _DailyWorkerCard({
    required this.worker,
    required this.onEdit,
  });

  final DailyWorker worker;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
            foregroundColor: theme.colorScheme.secondary,
            child: Text(worker.name.isNotEmpty ? worker.name[0].toUpperCase() : '?'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  worker.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.phone_rounded, size: 12, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      worker.phone.isEmpty ? 'Non renseigné' : worker.phone,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Journalier',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '${worker.salaireJournalier} F',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded, size: 20),
            style: IconButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurfaceVariant,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySectionPlaceholder extends StatelessWidget {
  const _EmptySectionPlaceholder({required this.label, required this.onAdd});
  final String label;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
            TextButton.icon(
              onPressed: onAdd, 
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Créer maintenant'),
            ),
          ],
        ),
      ),
    );
  }
}
