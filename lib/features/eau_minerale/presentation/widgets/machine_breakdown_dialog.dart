import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/bobine_usage.dart';
import '../../domain/entities/production_event.dart';
import '../../domain/entities/production_session.dart';

/// Dialog pour signaler une panne de machine et retirer la bobine.
class MachineBreakdownDialog extends ConsumerStatefulWidget {
  const MachineBreakdownDialog({
    super.key,
    required this.session,
    required this.bobine,
    required this.onPanneSignaled,
  });

  final ProductionSession session;
  final BobineUsage bobine;
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
  bool _retirerBobine = true;

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
      productionId: widget.session.id,
      type: ProductionEventType.panne,
      date: _selectedDate,
      heure: dateHeure,
      motif: _motifController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      createdAt: DateTime.now(),
    );

    // Si on retire la bobine, la marquer comme finie
    if (_retirerBobine) {
      final bobinesMisesAJour = widget.session.bobinesUtilisees.map((b) {
        if (b.bobineType == widget.bobine.bobineType &&
            b.machineId == widget.bobine.machineId) {
          return b.copyWith(
            estFinie: true,
            dateUtilisation: dateHeure,
          );
        }
        return b;
      }).toList();

      final sessionMiseAJour = widget.session.copyWith(
        bobinesUtilisees: bobinesMisesAJour,
        events: [...widget.session.events, event],
        updatedAt: DateTime.now(),
      );

      final controller = ref.read(productionSessionControllerProvider);
      await controller.updateSession(sessionMiseAJour);

      // Enregistrer le retour de stock pour la bobine retirée (ajoute à la quantité)
      final stockController = ref.read(stockControllerProvider);
      await stockController.recordBobineEntry(
        bobineType: widget.bobine.bobineType,
        quantite: 1, // Une bobine = 1 unité
        fournisseur: null,
        notes: 'Retour suite à panne - Machine ${widget.bobine.machineName}',
      );
    } else {
      // Juste enregistrer l'événement sans retirer la bobine
      final sessionMiseAJour = widget.session.copyWith(
        events: [...widget.session.events, event],
        updatedAt: DateTime.now(),
      );

      final controller = ref.read(productionSessionControllerProvider);
      await controller.updateSession(sessionMiseAJour);
    }

    if (!mounted) return;
    widget.onPanneSignaled(event);
    Navigator.of(context).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_retirerBobine
            ? 'Panne signalée et bobine retirée'
            : 'Panne signalée'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.build,
                    color: theme.colorScheme.error,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Signaler panne - ${widget.bobine.machineName}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Enregistrez la panne de la machine et retirez la bobine si nécessaire.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _motifController,
                decoration: const InputDecoration(
                  labelText: 'Motif de la panne *',
                  prefixIcon: Icon(Icons.description),
                  helperText: 'Description de la panne',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date *',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(_formatDate(_selectedDate)),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectTime(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Heure *',
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  child: Text(_formatTime(_selectedTime)),
                ),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Retirer la bobine de la machine'),
                subtitle: const Text(
                  'La bobine sera marquée comme finie et retournée au stock',
                ),
                value: _retirerBobine,
                onChanged: (value) {
                  setState(() => _retirerBobine = value ?? true);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: Icon(Icons.note),
                  helperText: 'Optionnel',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.check),
                      label: const Text('Enregistrer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }
}
