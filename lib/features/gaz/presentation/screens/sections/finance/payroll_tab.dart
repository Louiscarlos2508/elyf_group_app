import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/gaz_employee.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/gaz_salary_payment.dart';
import 'package:elyf_groupe_app/features/administration/application/providers.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import '../../../widgets/payroll/employee_form_dialog.dart';
import '../../../widgets/payroll/salary_payment_dialog.dart';

class PayrollTab extends ConsumerWidget {
  const PayrollTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeEnterprise = ref.watch(activeEnterpriseProvider).value;
    final enterpriseId = activeEnterprise?.id ?? '';
    
    final employeesAsync = ref.watch(gazEmployeesProvider(enterpriseId));
    final paymentsAsync = ref.watch(gazSalaryPaymentsProvider(enterpriseId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCards(context, ref, enterpriseId),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'EMPLOYÉS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showEmployeeDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Nouvel Employé'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildEmployeeList(context, employeesAsync),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'PAIEMENTS RÉCENTS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showPaymentDialog(context),
                  icon: const Icon(Icons.payment),
                  label: const Text('Enregistrer Salaire'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPaymentHistory(context, paymentsAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, WidgetRef ref, String enterpriseId) {
    final employeesAsync = ref.watch(gazEmployeesProvider(enterpriseId));
    final paymentsAsync = ref.watch(gazSalaryPaymentsProvider(enterpriseId));

    return Row(
      children: [
        Expanded(
          child: employeesAsync.when(
            data: (list) => _buildStatCard(
              context,
              'Total Employés',
              list.length.toString(),
              Icons.people_outline,
              Colors.blue,
            ),
            loading: () => ElyfShimmer.card(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: paymentsAsync.when(
            data: (list) {
              final total = list.fold<double>(0, (sum, p) => sum + p.amount);
              return _buildStatCard(
                context,
                'Total Payé (mois)',
                '${total.toStringAsFixed(0)} FCFA',
                Icons.account_balance_wallet_outlined,
                Colors.green,
              );
            },
            loading: () => ElyfShimmer.card(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return ElyfCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmployeeList(BuildContext context, AsyncValue<List<GazEmployee>> async) {
    return async.when(
      data: (employees) => employees.isEmpty 
        ? const Center(child: Text('Aucun employé'))
        : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final emp = employees[index];
              return ElyfCard(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.withValues(alpha: 0.1),
                    child: Text(emp.name[0]),
                  ),
                  title: Text(emp.name),
                  subtitle: Text('${emp.role} • ${emp.phone}'),
                  trailing: Text(
                    '${emp.baseSalary.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          ),
      loading: () => ElyfShimmer.listTile(),
      error: (e, _) => Text('Erreur: $e'),
    );
  }

  Widget _buildPaymentHistory(BuildContext context, AsyncValue<List<GazSalaryPayment>> async) {
    return async.when(
      data: (payments) => payments.isEmpty 
        ? const Center(child: Text('Aucun historique'))
        : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final p = payments[index];
              return ElyfCard(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.history, color: Colors.green),
                  title: Text(p.employeeName),
                  subtitle: Text('${p.period ?? ""} • ${p.paymentDate.day}/${p.paymentDate.month}/${p.paymentDate.year}'),
                  trailing: Text(
                    '${p.amount.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              );
            },
          ),
      loading: () => ElyfShimmer.listTile(),
      error: (e, _) => Text('Erreur: $e'),
    );
  }

  void _showEmployeeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => GazEmployeeFormDialog(),
    );
  }

  void _showPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => GazSalaryPaymentDialog(),
    );
  }
}
