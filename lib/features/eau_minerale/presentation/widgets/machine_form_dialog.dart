import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/machine.dart';

/// Dialog pour ajouter/modifier une machine.
class MachineFormDialog extends ConsumerStatefulWidget {
  const MachineFormDialog({super.key, this.machine});

  final Machine? machine;

  @override
  ConsumerState<MachineFormDialog> createState() => _MachineFormDialogState();
}

class _MachineFormDialogState extends ConsumerState<MachineFormDialog>
    with FormHelperMixin {
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
      _puissanceController.text = widget.machine!.puissanceKw?.toString() ?? '';
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
    await handleFormSubmit(
      context: context,
      formKey: _formKey,
      onLoadingChanged: (isLoading) => setState(() => _isLoading = isLoading),
      onSubmit: () async {
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
          await ref.read(machineControllerProvider).createMachine(machine);
        } else {
          await ref.read(machineControllerProvider).updateMachine(machine);
        }

        if (mounted) {
          Navigator.of(context).pop();
          ref.invalidate(allMachinesProvider);
        }

        return widget.machine == null ? 'Machine créée' : 'Machine modifiée';
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ElyfCard(
          isGlass: true,
          padding: EdgeInsets.zero,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with subtle gradient
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colors.primary.withValues(alpha: 0.1), colors.surface],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.machine == null ? Icons.add_to_photos_rounded : Icons.edit_note_rounded,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.machine == null ? 'Nouvelle Machine' : 'Modifier Machine',
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Configuration des équipements de production',
                              style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, size: 20),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Form Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _nomController,
                          decoration: _buildInputDecoration(
                            label: 'Nom de la Machine *',
                            hintText: 'Ex: Machine de remplissage A',
                            icon: Icons.precision_manufacturing_rounded,
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (value) => value?.trim().isEmpty ?? true ? 'Le nom est obligatoire' : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _referenceController,
                          decoration: _buildInputDecoration(
                            label: 'Référence / Modèle *',
                            hintText: 'Ex: MACH-001',
                            icon: Icons.tag_rounded,
                          ),
                          textCapitalization: TextCapitalization.characters,
                          validator: (value) => value?.trim().isEmpty ?? true ? 'La référence est obligatoire' : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _puissanceController,
                          decoration: _buildInputDecoration(
                            label: 'Puissance (kW)',
                            hintText: 'Ex: 5.5',
                            icon: Icons.bolt_rounded,
                            suffixText: 'kW',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                          validator: (value) {
                            if (value != null && value.trim().isNotEmpty && double.tryParse(value.trim()) == null) {
                              return 'Valeur invalide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Date Installation
                        _buildDateSelector(theme, colors),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _descriptionController,
                          decoration: _buildInputDecoration(
                            label: 'Description / Notes supplémentaires',
                            hintText: 'Détails sur l\'emplacement ou l\'état...',
                            icon: Icons.description_rounded,
                          ),
                          maxLines: 2,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        const SizedBox(height: 16),

                        // Status Switch
                        ElyfCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          borderRadius: 16,
                          backgroundColor: colors.surfaceContainerLow.withValues(alpha: 0.3),
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('Machine active', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                            subtitle: const Text('Permet d\'utiliser la machine en production', style: TextStyle(fontSize: 12)),
                            value: _estActive,
                            onChanged: (value) => setState(() => _estActive = value),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer Actions
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildSubmitButton(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector(ThemeData theme, ColorScheme colors) {
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outline.withValues(alpha: 0.1)),
          color: colors.surfaceContainerLow.withValues(alpha: 0.3),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month_rounded, size: 20, color: colors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date d\'installation', style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
                  Text(
                    _dateInstallation == null ? 'Non définie' : DateFormatter.formatNumericDate(_dateInstallation!),
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
    String? hintText,
    String? suffixText,
  }) {
    final colors = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      suffixText: suffixText,
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

  Widget _buildSubmitButton() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colors.primary, colors.secondary]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text(
            'ENREGISTRER LA CONFIGURATION',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
      ),
    );
  }
}
