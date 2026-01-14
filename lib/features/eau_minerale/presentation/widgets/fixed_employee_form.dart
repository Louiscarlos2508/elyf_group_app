import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/employee.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/notification_service.dart';

/// Form for creating/editing a fixed employee.
class FixedEmployeeForm extends ConsumerStatefulWidget {
  const FixedEmployeeForm({super.key, this.employee});

  final Employee? employee;

  @override
  ConsumerState<FixedEmployeeForm> createState() => FixedEmployeeFormState();
}

class FixedEmployeeFormState extends ConsumerState<FixedEmployeeForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _positionController = TextEditingController();
  final _monthlySalaryController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.employee != null) {
      final nameParts = widget.employee!.name.split(' ');
      _firstNameController.text = nameParts.isNotEmpty ? nameParts.first : '';
      _lastNameController.text = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';
      _positionController.text = widget.employee!.position ?? '';
      _monthlySalaryController.text = widget.employee!.monthlySalary.toString();
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _positionController.dispose();
    _monthlySalaryController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final employee = Employee(
        id:
            widget.employee?.id ??
            'emp-${DateTime.now().millisecondsSinceEpoch}',
        name:
            '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        phone: '', // Not required for fixed employees
        type: EmployeeType.fixed,
        monthlySalary: int.parse(_monthlySalaryController.text),
        position: _positionController.text.isEmpty
            ? null
            : _positionController.text.trim(),
        hireDate: widget.employee?.hireDate ?? DateTime.now(),
      );

      if (widget.employee == null) {
        await ref.read(salaryControllerProvider).createFixedEmployee(employee);
      } else {
        await ref.read(salaryControllerProvider).updateEmployee(employee);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      ref.invalidate(salaryStateProvider);
      NotificationService.showInfo(
        context,
        widget.employee == null ? 'Employé créé' : 'Employé modifié',
      );
    } catch (e) {
      if (!mounted) return;
      NotificationService.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'Prénom *',
                prefixIcon: Icon(Icons.person_outline),
                hintText: 'Ex: Jean',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Nom *',
                prefixIcon: Icon(Icons.person),
                hintText: 'Ex: Dupont',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _positionController,
              decoration: const InputDecoration(
                labelText: 'Poste',
                prefixIcon: Icon(Icons.work_outline),
                hintText: 'Ex: Vendeur, Gérant...',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _monthlySalaryController,
              decoration: const InputDecoration(
                labelText: 'Salaire Mensuel (FCFA) *',
                prefixIcon: Icon(Icons.attach_money),
                hintText: 'Ex: 150000',
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requis';
                final salary = int.tryParse(v);
                if (salary == null || salary <= 0) return 'Salaire invalide';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
