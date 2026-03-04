import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/gaz_employee.dart';
import 'package:elyf_groupe_app/features/administration/application/providers.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';

class GazEmployeeFormDialog extends ConsumerStatefulWidget {
  final GazEmployee? employee;

  const GazEmployeeFormDialog({super.key, this.employee});

  @override
  ConsumerState<GazEmployeeFormDialog> createState() => _GazEmployeeFormDialogState();
}

class _GazEmployeeFormDialogState extends ConsumerState<GazEmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _roleController;
  late TextEditingController _salaryController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.employee?.name);
    _phoneController = TextEditingController(text: widget.employee?.phone);
    _roleController = TextEditingController(text: widget.employee?.role);
    _salaryController = TextEditingController(text: widget.employee?.baseSalary.toStringAsFixed(0));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.employee == null ? 'Nouvel Employé' : 'Modifier Employé'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom complet'),
                validator: (v) => v?.isEmpty == true ? 'Champs requis' : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Téléphone'),
                validator: (v) => v?.isEmpty == true ? 'Champs requis' : null,
              ),
              TextFormField(
                controller: _roleController,
                decoration: const InputDecoration(labelText: 'Rôle/Poste'),
                validator: (v) => v?.isEmpty == true ? 'Champs requis' : null,
              ),
              TextFormField(
                controller: _salaryController,
                decoration: const InputDecoration(labelText: 'Salaire de base (FCFA)'),
                keyboardType: TextInputType.number,
                validator: (v) => v?.isEmpty == true ? 'Champs requis' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text;
    final phone = _phoneController.text;
    final role = _roleController.text;
    final salary = double.tryParse(_salaryController.text) ?? 0;
    
    final activeEnterprise = ref.read(activeEnterpriseProvider).value;
    if (activeEnterprise == null) return;

    final employee = widget.employee?.copyWith(
      name: name,
      phone: phone,
      role: role,
      baseSalary: salary,
    ) ?? GazEmployee(
      id: const Uuid().v4(),
      enterpriseId: activeEnterprise.id,
      name: name,
      phone: phone,
      role: role,
      baseSalary: salary,
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(gazEmployeeControllerProvider).saveEmployee(employee);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) NotificationService.showError(context, 'Erreur: $e');
    }
  }
}
