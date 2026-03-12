import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/gaz_employee.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/gaz_salary_payment.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';

import '../../../../../shared/domain/entities/payment_method.dart';

class GazSalaryPaymentDialog extends ConsumerStatefulWidget {
  const GazSalaryPaymentDialog({super.key});

  @override
  ConsumerState<GazSalaryPaymentDialog> createState() => _GazSalaryPaymentDialogState();
}

class _GazSalaryPaymentDialogState extends ConsumerState<GazSalaryPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  GazEmployee? _selectedEmployee;
  late TextEditingController _amountController;
  late TextEditingController _periodController;
  late TextEditingController _notesController;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _periodController = TextEditingController(text: _getCurrentPeriod());
    _notesController = TextEditingController();
  }

  String _getCurrentPeriod() {
    final now = DateTime.now();
    final months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final activeEnterprise = ref.watch(activeEnterpriseProvider).value;
    final enterpriseId = activeEnterprise?.id ?? '';
    final employeesAsync = ref.watch(gazEmployeesProvider(enterpriseId));

    return AlertDialog(
      title: const Text('Enregistrer un Salaire'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              employeesAsync.when(
                data: (employees) => DropdownButtonFormField<GazEmployee>(
                  initialValue: _selectedEmployee,
                  items: employees.map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e.name),
                  )).toList(),
                  onChanged: (e) {
                    setState(() {
                      _selectedEmployee = e;
                      if (e != null) {
                        _amountController.text = e.baseSalary.toStringAsFixed(0);
                      }
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Employé'),
                  validator: (v) => v == null ? 'Veuillez choisir un employé' : null,
                ),
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('Erreur chargement employés'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Montant (FCFA)'),
                keyboardType: TextInputType.number,
                validator: (v) => v?.isEmpty == true ? 'Champs requis' : null,
              ),
              TextFormField(
                controller: _periodController,
                decoration: const InputDecoration(labelText: 'Période (Mois Année)'),
                validator: (v) => v?.isEmpty == true ? 'Champs requis' : null,
              ),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes (Optionnel)'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PaymentMethod>(
                initialValue: _selectedPaymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Mode de Paiement',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
                items: [
                  DropdownMenuItem(
                    value: PaymentMethod.cash,
                    child: Text(PaymentMethod.cash.label),
                  ),
                  const DropdownMenuItem(
                    value: PaymentMethod.mobileMoney,
                    child: Text('Orange Money'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedPaymentMethod = val);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Enregistrer le paiement'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedEmployee == null) return;

    final amount = double.tryParse(_amountController.text) ?? 0;
    
    final activeEnterprise = ref.read(activeEnterpriseProvider).value;
    if (activeEnterprise == null) return;

    final payment = GazSalaryPayment(
      id: const Uuid().v4(),
      enterpriseId: activeEnterprise.id,
      employeeId: _selectedEmployee!.id,
      employeeName: _selectedEmployee!.name,
      amount: amount,
      paymentDate: DateTime.now(),
      period: _periodController.text,
      notes: _notesController.text,
      paymentMethod: _selectedPaymentMethod,
      treasuryOperationId: const Uuid().v4(),
    );

    try {
      final userId = ref.read(currentUserIdProvider);
      await ref.read(gazSalaryPaymentControllerProvider).recordPayment(payment, userId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) NotificationService.showError(context, 'Erreur: $e');
    }
  }
}
