import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/machine_material_usage.dart';
import 'package:elyf_groupe_app/shared.dart';

/// Dialog pour signaler une panne de machine et retirer la matière.
/// (Anciennement MachineBreakdownDialog).
class MachineBreakdownDialog extends ConsumerStatefulWidget {
  const MachineBreakdownDialog({
    super.key,
    required this.machine,
    this.session,
    this.material,
    required this.onPanneSignaled,
  });

  final Machine machine;
  final ProductionSession? session;
  final MachineMaterialUsage? material;
  final ValueChanged<ProductionEvent> onPanneSignaled;

  @override
  ConsumerState<MachineBreakdownDialog> createState() =>
      _MachineBreakdownDialogState();
}

class _MachineBreakdownDialogState
    extends ConsumerState<MachineBreakdownDialog> {
  final _formKey = GlobalKey<FormState>();
  final _motifController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  late bool _retirerMatiere;

  bool get _hasMaterial => widget.material != null;
  bool get _hasSession => widget.session != null;

  @override
  void initState() {
    super.initState();
    _retirerMatiere = _hasMaterial;
  }

  @override
  void dispose() {
    _motifController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final dateHeure = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final event = ProductionEvent(
      id: 'event-${DateTime.now().millisecondsSinceEpoch}',
      productionId:
          widget.session?.id ??
          'standalone-${DateTime.now().millisecondsSinceEpoch}',
      type: ProductionEventType.panne,
      date: _selectedDate,
      heure: dateHeure,
      motif: _motifController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      createdAt: DateTime.now(),
    );

    if (_hasSession && _hasMaterial && _retirerMatiere) {
      final materialsMisesAJour = widget.session!.machineMaterials.map((m) {
        if (m.materialType == widget.material!.materialType &&
            m.machineId == widget.material!.machineId) {
          return m.copyWith(estFinie: true, dateUtilisation: dateHeure);
        }
        return m;
      }).toList();

      final sessionMiseAJour = widget.session!.copyWith(
        machineMaterials: materialsMisesAJour,
        events: [...widget.session!.events, event],
        updatedAt: DateTime.now(),
      );

      final controller = ref.read(productionSessionControllerProvider);
      await controller.updateSession(sessionMiseAJour);

      final stockController = ref.read(stockControllerProvider);
      await stockController.recordEntry(
        productId: widget.material!.productId ?? '',
        productName: widget.material!.productName ?? widget.material!.materialType,
        quantite: 1, 
        raison: 'Retour suite à panne - Machine ${widget.material!.machineName}',
        notes: 'Retour suite à panne - Machine ${widget.material!.machineName}',
      );
    } else if (_hasSession) {
      final sessionMiseAJour = widget.session!.copyWith(
        events: [...widget.session!.events, event],
        updatedAt: DateTime.now(),
      );

      final controller = ref.read(productionSessionControllerProvider);
      await controller.updateSession(sessionMiseAJour);
    }

    final machineMiseAJour = widget.machine.copyWith(
      isActive: false,
      updatedAt: DateTime.now(),
    );
    
    final machineController = ref.read(machineControllerProvider);
    await machineController.updateMachine(machineMiseAJour);

    ref.invalidate(allMachinesProvider);

    if (!mounted) return;
    widget.onPanneSignaled(event);
    Navigator.of(context).pop();

    NotificationService.showInfo(
      context,
      _retirerMatiere && _hasMaterial
          ? 'Panne signalée et matière retirée'
          : 'Panne signalée',
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
        constraints: const BoxConstraints(maxWidth: 500),
        child: ElyfCard(
          isGlass: false,
          padding: EdgeInsets.zero,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colors.error.withValues(alpha: 0.1), colors.surface],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.build_circle_rounded, color: colors.error, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Signaler Panne',
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              widget.machine.name,
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

                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _motifController,
                          decoration: _buildInputDecoration(
                            label: 'Motif de la panne *',
                            hintText: 'Décrivez le problème rencontré...',
                            icon: Icons.error_outline_rounded,
                          ),
                          maxLines: 3,
                          validator: (v) => v?.trim().isEmpty ?? true ? 'Le motif est requis' : null,
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(child: _buildDateTimePicker(theme, colors, isDate: true)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildDateTimePicker(theme, colors, isDate: false)),
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (_hasMaterial) ...[
                          ElyfCard(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            borderRadius: 16,
                            backgroundColor: colors.primary.withValues(alpha: 0.05),
                            borderColor: colors.primary.withValues(alpha: 0.1),
                            child: CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Retirer matière', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text(
                                'Retour au stock (${widget.material!.materialType})',
                                style: const TextStyle(fontSize: 11),
                              ),
                              value: _retirerMatiere,
                              onChanged: (value) => setState(() => _retirerMatiere = value ?? true),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        TextFormField(
                          controller: _notesController,
                          decoration: _buildInputDecoration(
                            label: 'Notes / Actions effectuées',
                            hintText: 'Ex: Appel technicien, pièce à changer...',
                            icon: Icons.note_alt_rounded,
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),

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

  Widget _buildDateTimePicker(ThemeData theme, ColorScheme colors, {required bool isDate}) {
    return InkWell(
      onTap: () => isDate ? _selectDate(context) : _selectTime(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: colors.surfaceContainerLow.withValues(alpha: 0.3),
          border: Border.all(color: colors.outline.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isDate ? Icons.calendar_today_rounded : Icons.access_time_rounded, size: 14, color: colors.primary),
                const SizedBox(width: 6),
                Text(isDate ? 'Date' : 'Heure', style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isDate ? DateFormatter.formatNumericDate(_selectedDate) : _formatTime(_selectedTime),
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colors.outline.withValues(alpha: 0.1))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colors.outline.withValues(alpha: 0.1))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colors.primary, width: 2)),
      filled: true,
      fillColor: colors.surfaceContainerLow.withValues(alpha: 0.3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildSubmitButton() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colors.error, colors.error.withValues(alpha: 0.7)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: colors.error.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: ElevatedButton(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text('ENREGISTRER LA PANNE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }
}
