import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/bobine.dart';
import '../../domain/entities/bobine_usage.dart';
import '../../domain/entities/machine.dart';
import '../../domain/entities/production_period_config.dart';
import '../../domain/entities/production_session.dart';
import 'bobine_usage_form_field.dart';
import 'form_dialog.dart';
import 'machine_selector_field.dart';
import 'time_picker_field.dart';

/// Formulaire pour créer/éditer une session de production.
class ProductionSessionForm extends ConsumerStatefulWidget {
  const ProductionSessionForm({
    super.key,
    this.session,
  });

  final ProductionSession? session;

  @override
  ConsumerState<ProductionSessionForm> createState() =>
      ProductionSessionFormState();
}

class ProductionSessionFormState
    extends ConsumerState<ProductionSessionForm> {
  final _formKey = GlobalKey<FormState>();
  final _indexDebutController = TextEditingController();
  final _indexFinController = TextEditingController();
  final _consommationController = TextEditingController();
  final _quantiteController = TextEditingController();
  final _emballagesController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  DateTime _heureDebut = DateTime.now();
  DateTime _heureFin = DateTime.now().add(const Duration(hours: 2));
  List<String> _machinesSelectionnees = [];
  List<BobineUsage> _bobinesUtilisees = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.session != null) {
      _initialiserAvecSession(widget.session!);
    }
  }

  void _initialiserAvecSession(ProductionSession session) {
    _selectedDate = session.date;
    _heureDebut = session.heureDebut;
    _heureFin = session.heureFin;
    _indexDebutController.text = session.indexCompteurDebut.toString();
    _indexFinController.text = session.indexCompteurFin.toString();
    _consommationController.text = session.consommationCourant.toString();
    _quantiteController.text = session.quantiteProduite.toString();
    _emballagesController.text = session.emballagesUtilises?.toString() ?? '';
    _notesController.text = session.notes ?? '';
    _machinesSelectionnees = List.from(session.machinesUtilisees);
    _bobinesUtilisees = List.from(session.bobinesUtilisees);
  }

  @override
  void dispose() {
    _indexDebutController.dispose();
    _indexFinController.dispose();
    _consommationController.dispose();
    _quantiteController.dispose();
    _emballagesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int? get _indexDebut => int.tryParse(_indexDebutController.text);
  int? get _indexFin => int.tryParse(_indexFinController.text);
  int? get _consommationEau =>
      _indexDebut != null && _indexFin != null ? _indexFin! - _indexDebut! : null;

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_machinesSelectionnees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez au moins une machine')),
      );
      return;
    }
    if (_bobinesUtilisees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez au moins une bobine utilisée')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final config = await ref
          .read(productionPeriodConfigProvider.future);
      final session = ProductionSession(
        id: widget.session?.id ?? '',
        date: _selectedDate,
        period: config.getPeriodForDate(_selectedDate),
        heureDebut: _heureDebut,
        heureFin: _heureFin,
        indexCompteurDebut: _indexDebut!,
        indexCompteurFin: _indexFin!,
        consommationCourant: double.parse(_consommationController.text),
        machinesUtilisees: _machinesSelectionnees,
        bobinesUtilisees: _bobinesUtilisees,
        quantiteProduite: int.parse(_quantiteController.text),
        quantiteProduiteUnite: 'pack',
        emballagesUtilises: _emballagesController.text.isNotEmpty
            ? int.tryParse(_emballagesController.text)
            : null,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      final controller = ref.read(productionSessionControllerProvider);
      if (widget.session == null) {
        await controller.createSession(session);
      } else {
        await controller.updateSession(session);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      ref.invalidate(productionSessionsStateProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.session == null
              ? 'Session créée avec succès'
              : 'Session mise à jour'),
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
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDateField(),
            const SizedBox(height: 16),
            _buildTimeFields(),
            const SizedBox(height: 16),
            _buildIndexFields(),
            const SizedBox(height: 16),
            _buildConsommationField(),
            const SizedBox(height: 16),
            MachineSelectorField(
              machinesSelectionnees: _machinesSelectionnees,
              onMachinesChanged: (machines) {
                setState(() => _machinesSelectionnees = machines);
              },
            ),
            const SizedBox(height: 16),
            BobineUsageFormField(
              bobinesUtilisees: _bobinesUtilisees,
              machinesDisponibles: _machinesSelectionnees,
              onBobinesChanged: (bobines) {
                setState(() => _bobinesUtilisees = bobines);
              },
            ),
            const SizedBox(height: 16),
            _buildQuantiteField(),
            const SizedBox(height: 16),
            _buildEmballagesField(),
            const SizedBox(height: 16),
            _buildNotesField(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date',
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(_formatDate(_selectedDate)),
      ),
    );
  }

  Widget _buildTimeFields() {
    return Row(
      children: [
        Expanded(
          child: TimePickerField(
            label: 'Heure début',
            initialTime: TimeOfDay.fromDateTime(_heureDebut),
            onTimeSelected: (time) {
              setState(() {
                _heureDebut = DateTime(
                  _selectedDate.year,
                  _selectedDate.month,
                  _selectedDate.day,
                  time.hour,
                  time.minute,
                );
              });
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TimePickerField(
            label: 'Heure fin',
            initialTime: TimeOfDay.fromDateTime(_heureFin),
            onTimeSelected: (time) {
              setState(() {
                _heureFin = DateTime(
                  _selectedDate.year,
                  _selectedDate.month,
                  _selectedDate.day,
                  time.hour,
                  time.minute,
                );
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIndexFields() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _indexDebutController,
            decoration: const InputDecoration(
              labelText: 'Index compteur début',
              prefixIcon: Icon(Icons.water_drop),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Requis';
              }
              if (int.tryParse(value) == null) {
                return 'Nombre invalide';
              }
              return null;
            },
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: _indexFinController,
            decoration: const InputDecoration(
              labelText: 'Index compteur fin',
              prefixIcon: Icon(Icons.water_drop),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Requis';
              }
              if (int.tryParse(value) == null) {
                return 'Nombre invalide';
              }
              if (_indexDebut != null && int.parse(value) < _indexDebut!) {
                return 'Doit être >= index début';
              }
              return null;
            },
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildConsommationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _consommationController,
          decoration: const InputDecoration(
            labelText: 'Consommation courant (kWh)',
            prefixIcon: Icon(Icons.bolt),
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Requis';
            }
            if (double.tryParse(value) == null) {
              return 'Nombre invalide';
            }
            return null;
          },
        ),
        if (_consommationEau != null) ...[
          const SizedBox(height: 8),
          Text(
            'Consommation eau: $_consommationEau L',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuantiteField() {
    return TextFormField(
      controller: _quantiteController,
      decoration: const InputDecoration(
        labelText: 'Quantité produite (packs)',
        prefixIcon: Icon(Icons.inventory_2),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Requis';
        }
        if (int.tryParse(value) == null || int.parse(value) <= 0) {
          return 'Nombre invalide';
        }
        return null;
      },
    );
  }

  Widget _buildEmballagesField() {
    return TextFormField(
      controller: _emballagesController,
      decoration: const InputDecoration(
        labelText: 'Emballages utilisés (packs)',
        prefixIcon: Icon(Icons.inventory_2),
        helperText: 'Optionnel',
      ),
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: const InputDecoration(
        labelText: 'Notes',
        prefixIcon: Icon(Icons.note),
        helperText: 'Optionnel',
      ),
      maxLines: 3,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}


