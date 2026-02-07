import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/bobine_usage.dart';
import '../../domain/entities/machine.dart';
import '../../domain/entities/production_event.dart';
import '../../domain/entities/production_session.dart';
import 'package:elyf_groupe_app/shared.dart';

/// Dialog pour signaler une panne de machine et retirer la bobine.
class MachineBreakdownDialog extends ConsumerStatefulWidget {
  const MachineBreakdownDialog({
    super.key,
    required this.machine,
    this.session,
    this.bobine,
    required this.onPanneSignaled,
  });

  final Machine machine;
  final ProductionSession? session;
  final BobineUsage? bobine;
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
  late bool _retirerBobine;

  bool get _hasBobine => widget.bobine != null;
  bool get _hasSession => widget.session != null;

  @override
  void initState() {
    super.initState();
    _retirerBobine = _hasBobine;
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

    // Créer l'événement de panne
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

    // Si on a une session et une bobine, et qu'on veut retirer la bobine
    if (_hasSession && _hasBobine && _retirerBobine) {
      final bobinesMisesAJour = widget.session!.bobinesUtilisees.map((b) {
        if (b.bobineType == widget.bobine!.bobineType &&
            b.machineId == widget.bobine!.machineId) {
          return b.copyWith(estFinie: true, dateUtilisation: dateHeure);
        }
        return b;
      }).toList();

      final sessionMiseAJour = widget.session!.copyWith(
        bobinesUtilisees: bobinesMisesAJour,
        events: [...widget.session!.events, event],
        updatedAt: DateTime.now(),
      );

      final controller = ref.read(productionSessionControllerProvider);
      await controller.updateSession(sessionMiseAJour);

      // Enregistrer le retour de stock pour la bobine retirée (ajoute à la quantité)
      final stockController = ref.read(stockControllerProvider);
      await stockController.recordBobineEntry(
        bobineType: widget.bobine!.bobineType,
        quantite: 1, // Une bobine = 1 unité
        fournisseur: null,
        notes: 'Retour suite à panne - Machine ${widget.bobine!.machineName}',
      );
    } else if (_hasSession) {
      // Juste enregistrer l'événement sans retirer la bobine
      final sessionMiseAJour = widget.session!.copyWith(
        events: [...widget.session!.events, event],
        updatedAt: DateTime.now(),
      );

      final controller = ref.read(productionSessionControllerProvider);
      await controller.updateSession(sessionMiseAJour);
    }
    // Si pas de session, on enregistre juste l'événement de panne (signalement standalone)

    if (!mounted) return;
    widget.onPanneSignaled(event);
    Navigator.of(context).pop();

    NotificationService.showInfo(
      context,
      _retirerBobine && _hasBobine
          ? 'Panne signalée et bobine retirée'
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
                              widget.machine.nom,
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

                        // Date & Time
                        Row(
                          children: [
                            Expanded(child: _buildDateTimePicker(theme, colors, isDate: true)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildDateTimePicker(theme, colors, isDate: false)),
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (_hasBobine) ...[
                          ElyfCard(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            borderRadius: 16,
                            backgroundColor: colors.primary.withValues(alpha: 0.05),
                            borderColor: colors.primary.withValues(alpha: 0.1),
                            child: CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Retirer bobine', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text(
                                'Retour au stock (${widget.bobine!.bobineType})',
                                style: const TextStyle(fontSize: 11),
                              ),
                              value: _retirerBobine,
                              onChanged: (value) => setState(() => _retirerBobine = value ?? true),
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

                // Footer
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
