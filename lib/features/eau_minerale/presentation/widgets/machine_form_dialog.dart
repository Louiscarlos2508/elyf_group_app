import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/machine.dart';
import 'machine_selector_field.dart';

/// Dialog pour ajouter/modifier une machine.
class MachineFormDialog extends ConsumerStatefulWidget {
  const MachineFormDialog({super.key, this.machine});

  final Machine? machine;

  @override
  ConsumerState<MachineFormDialog> createState() =>
      _MachineFormDialogState();
}

class _MachineFormDialogState extends ConsumerState<MachineFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _referenceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _puissanceController = TextEditingController();
  bool _estActive = true;
  DateTime? _dateInstallation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.machine != null) {
      _nomController.text = widget.machine!.nom;
      _referenceController.text = widget.machine!.reference;
      _descriptionController.text = widget.machine!.description ?? '';
      _puissanceController.text =
          widget.machine!.puissanceKw?.toString() ?? '';
      _estActive = widget.machine!.estActive;
      _dateInstallation = widget.machine!.dateInstallation;
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _referenceController.dispose();
    _descriptionController.dispose();
    _puissanceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateInstallation ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dateInstallation = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final machine = Machine(
        id: widget.machine?.id ?? '',
        nom: _nomController.text.trim(),
        reference: _referenceController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        estActive: _estActive,
        puissanceKw: _puissanceController.text.trim().isEmpty
            ? null
            : double.tryParse(_puissanceController.text.trim()),
        dateInstallation: _dateInstallation,
        createdAt: widget.machine?.createdAt,
        updatedAt: DateTime.now(),
      );

      if (widget.machine == null) {
        await ref.read(machineRepositoryProvider).createMachine(machine);
      } else {
        await ref.read(machineRepositoryProvider).updateMachine(machine);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      ref.invalidate(allMachinesProvider);
      ref.invalidate(machinesProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.machine == null
              ? 'Machine créée'
              : 'Machine modifiée'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.machine == null
                            ? 'Nouvelle machine'
                            : 'Modifier la machine',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nomController,
                        decoration: const InputDecoration(
                          labelText: 'Nom *',
                          hintText: 'Ex: Machine de remplissage A',
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le nom est obligatoire';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _referenceController,
                        decoration: const InputDecoration(
                          labelText: 'Référence *',
                          hintText: 'Ex: MACH-001',
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'La référence est obligatoire';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Description de la machine',
                        ),
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _puissanceController,
                        decoration: const InputDecoration(
                          labelText: 'Puissance (kW)',
                          hintText: 'Ex: 5.5',
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        validator: (value) {
                          if (value != null &&
                              value.trim().isNotEmpty &&
                              double.tryParse(value.trim()) == null) {
                            return 'Valeur invalide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Date d\'installation',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _selectDate,
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: Text(
                              _dateInstallation == null
                                  ? 'Sélectionner'
                                  : '${_dateInstallation!.day}/${_dateInstallation!.month}/${_dateInstallation!.year}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Machine active'),
                        subtitle: const Text(
                          'Les machines inactives ne peuvent pas être utilisées',
                        ),
                        value: _estActive,
                        onChanged: (value) =>
                            setState(() => _estActive = value),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IntrinsicWidth(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('Annuler'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Enregistrer'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
