import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../domain/entities/production_event.dart';

/// Dialog pour enregistrer un événement (panne, coupure, arrêt forcé)
/// pendant une production.
class ProductionEventDialog extends StatefulWidget {
  const ProductionEventDialog({
    super.key,
    required this.productionId,
    required this.onEventRecorded,
  });

  final String productionId;
  final ValueChanged<ProductionEvent> onEventRecorded;

  @override
  State<ProductionEventDialog> createState() => _ProductionEventDialogState();
}

class _ProductionEventDialogState extends State<ProductionEventDialog> {
  final _formKey = GlobalKey<FormState>();
  ProductionEventType? _selectedType;
  final _motifController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    _motifController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null) {
      NotificationService.showWarning(
        context,
        'Sélectionnez un type d\'événement',
      );
      return;
    }

    final dateHeure = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final event = ProductionEvent(
      id: 'event-${DateTime.now().millisecondsSinceEpoch}',
      productionId: widget.productionId,
      type: _selectedType!,
      date: _selectedDate,
      heure: dateHeure,
      motif: _motifController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      createdAt: DateTime.now(),
    );

    widget.onEventRecorded(event);
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
          backgroundColor: colors.surface,
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
                    color: colors.surfaceContainerLow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.event_note_rounded, color: colors.primary, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Enregistrer Événement',
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Signalement d\'un incident de production',
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
                        Text(
                          'Type d\'événement *',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: colors.primary),
                        ),
                        const SizedBox(height: 12),
                        ElyfCard(
                          padding: EdgeInsets.zero,
                          borderRadius: 20,
                          backgroundColor: colors.surfaceContainerLow,
                          child: Column(
                            children: ProductionEventType.values.map((type) {
                              return RadioListTile<ProductionEventType>(
                                title: Row(
                                  children: [
                                    Text(type.icon, style: const TextStyle(fontSize: 18)),
                                    const SizedBox(width: 12),
                                    Text(type.label, style: theme.textTheme.bodyMedium),
                                  ],
                                ),
                                value: type,
                                // ignore: deprecated_member_use - RadioGroup migration deferred
                                groupValue: _selectedType,
                                // ignore: deprecated_member_use - RadioGroup migration deferred
                                onChanged: (v) => setState(() => _selectedType = v),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _motifController,
                          decoration: _buildInputDecoration(
                            label: 'Motif *',
                            hintText: 'Décrivez brièvement l\'incident...',
                            icon: Icons.info_outline_rounded,
                          ),
                          maxLines: 2,
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

                        TextFormField(
                          controller: _notesController,
                          decoration: _buildInputDecoration(
                            label: 'Notes (Optionnel)',
                            hintText: 'Détails supplémentaires...',
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
          color: colors.surfaceContainerLow,
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
      fillColor: colors.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildSubmitButton() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colors.primary, colors.secondary]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: colors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
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
        child: const Text('ENREGISTRER L\'ÉVÉNEMENT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
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
