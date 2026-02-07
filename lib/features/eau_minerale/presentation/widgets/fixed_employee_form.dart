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
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Informations Personnelles',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.primary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstNameController,
                    decoration: _buildInputDecoration(
                      label: 'Prénom *',
                      icon: Icons.person_outline_rounded,
                      hintText: 'Ex: Jean',
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lastNameController,
                    decoration: _buildInputDecoration(
                      label: 'Nom *',
                      icon: Icons.person_rounded,
                      hintText: 'Ex: Dupont',
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Informations Professionnelles',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.primary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _positionController,
              decoration: _buildInputDecoration(
                label: 'Poste / Titre',
                icon: Icons.work_outline_rounded,
                hintText: 'Ex: Vendeur, Gérant, Technicien...',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _monthlySalaryController,
              decoration: _buildInputDecoration(
                label: 'Salaire Mensuel (FCFA) *',
                icon: Icons.payments_outlined,
                hintText: 'Ex: 150 000',
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

  InputDecoration _buildInputDecoration({required String label, required IconData icon, String? hintText}) {
    final colors = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: Icon(icon, size: 20, color: colors.primary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
      filled: true,
      fillColor: colors.surfaceContainerLow.withValues(alpha: 0.3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
