import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/services/electricity_meter_config_service.dart';
import '../../domain/entities/bobine_usage.dart';
import '../../domain/entities/production_day.dart';
import '../../domain/entities/production_session.dart';
import '../../domain/entities/production_session_status.dart';
import '../../domain/services/production_session_builder.dart';
import '../../domain/services/production_session_validation_service.dart';
import 'bobine_usage_form_field.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'machine_selector_field.dart';
import 'time_picker_field.dart';

/// Formulaire pour créer/éditer une session de production.
class ProductionSessionForm extends ConsumerStatefulWidget {
  const ProductionSessionForm({super.key, this.session});

  final ProductionSession? session;

  @override
  ConsumerState<ProductionSessionForm> createState() =>
      ProductionSessionFormState();
}

class ProductionSessionFormState extends ConsumerState<ProductionSessionForm> {
  final _formKey = GlobalKey<FormState>();
  final _consommationController = TextEditingController();
  final _coutElectriciteController = TextEditingController();
  final _coutBobinesController = TextEditingController();
  final _quantiteController = TextEditingController();
  final _emballagesController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  DateTime _heureDebut = DateTime.now();
  DateTime _heureFin = DateTime.now().add(const Duration(hours: 2));
  List<String> _machinesSelectionnees = [];
  List<BobineUsage> _bobinesUtilisees = [];
  List<ProductionDay> _existingProductionDays = [];
  bool _isLoading = false;
  bool _isTermine = false;

  // Configuration (valeurs par défaut, à récupérer depuis les configs)
  double _electricityRate = 125.0; // CFA par kWh
  Map<String, int> _bobineUnitPrices = {}; // Prix unitaire par type de bobine

  @override
  void initState() {
    super.initState();
    _loadConfigurations();
    if (widget.session != null) {
      _initialiserAvecSession(widget.session!);
    }
    
    // Auto-calcul coût électricité lors du changement de consommation
    _consommationController.addListener(_updateElectricityCost);
  }

  Future<void> _loadConfigurations() async {
    try {
      final configService = ElectricityMeterConfigService.instance;
      final rate = await configService.getElectricityRate();
      
      final stocks = await ref.read(stockStateProvider.future);
      final prices = <String, int>{};
      for (final stock in stocks.bobineStocks) {
        if (stock.prixUnitaire != null) {
          prices[stock.type] = stock.prixUnitaire!;
        }
      }
      
      if (mounted) {
        setState(() {
          _electricityRate = rate;
          _bobineUnitPrices = prices;
        });
        
        // Si c'est une nouvelle session, calculer le coût initial des bobines si déjà sélectionnées
        if (widget.session == null && _bobinesUtilisees.isNotEmpty) {
          _updateBobineCost();
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des configs: $e');
    }
  }


  void _initialiserAvecSession(ProductionSession session) {
    _selectedDate = session.date;
    _heureDebut = session.heureDebut;
    _heureFin = session.heureFin ?? DateTime.now();
    _consommationController.text = session.consommationCourant.toString();
    _coutElectriciteController.text = (session.coutElectricite ?? 0).toString();
    _coutBobinesController.text = (session.coutBobines ?? 0).toString();
    _quantiteController.text = session.quantiteProduite.toString();
    _emballagesController.text = session.emballagesUtilises?.toString() ?? '';
    _notesController.text = session.notes ?? '';
    _machinesSelectionnees = List.from(session.machinesUtilisees);
    _bobinesUtilisees = List.from(session.bobinesUtilisees);
    // Préserver les jours de production existants
    _existingProductionDays = List.from(session.productionDays);
    _isTermine = session.status == ProductionSessionStatus.completed;
  }

  void _updateElectricityCost() {
    final kwh = double.tryParse(_consommationController.text) ?? 0.0;
    final cost = (kwh * _electricityRate).round();
    if (_coutElectriciteController.text != cost.toString()) {
       _coutElectriciteController.text = cost.toString();
    }
  }

  void _updateBobineCost() {
    int totalCost = 0;
    for (final bobine in _bobinesUtilisees) {
      // Chercher le prix pour ce type de bobine
      // TODO: Gérer les types de manière plus robuste (normalisation des noms)
      final price = _bobineUnitPrices[bobine.bobineType] ?? 0;
      totalCost += price;
    }
    _coutBobinesController.text = totalCost.toString();
  }

  @override
  void dispose() {
    _consommationController.removeListener(_updateElectricityCost);
    _consommationController.dispose();
    _coutElectriciteController.dispose();
    _coutBobinesController.dispose();
    _quantiteController.dispose();
    _emballagesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validation : machines et bobines
    final machinesBobinesError =
        ProductionSessionValidationService.validateMachinesAndBobines(
          machines: _machinesSelectionnees,
          bobines: _bobinesUtilisees,
        );
    if (machinesBobinesError != null) {
      NotificationService.showWarning(context, machinesBobinesError);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final config = await ref.read(productionPeriodConfigProvider.future);
      
      final coutElec = int.tryParse(_coutElectriciteController.text.replaceAll(RegExp(r'[^0-9]'), ''));
      final coutBob = int.tryParse(_coutBobinesController.text.replaceAll(RegExp(r'[^0-9]'), ''));

      final session = ProductionSessionBuilder.buildFromForm(
        sessionId: widget.session?.id,
        selectedDate: _selectedDate,
        heureDebut: _heureDebut,
        heureFin: widget.session?.heureFin, // Préserver l'heure de fin si elle existe
        indexCompteurInitialKwh: null,
        indexCompteurFinalKwh: null,
        consommationCourant: double.parse(_consommationController.text),
        machinesUtilisees: _machinesSelectionnees,
        bobinesUtilisees: _bobinesUtilisees,
        quantiteProduite: int.parse(_quantiteController.text),
        emballagesUtilises: _emballagesController.text.isNotEmpty
            ? int.tryParse(_emballagesController.text)
            : null,
        coutBobines: coutBob,
        coutElectricite: coutElec,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        status: _isTermine 
            ? ProductionSessionStatus.completed 
            : (widget.session?.status == ProductionSessionStatus.completed 
                ? ProductionSessionStatus.inProgress 
                : widget.session?.status),
        productionDays: _existingProductionDays, // Préserver les données existantes
        period: config.getPeriodForDate(_selectedDate),
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
      NotificationService.showInfo(
        context,
        widget.session == null
            ? 'Session créée avec succès'
            : 'Session mise à jour',
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
            _buildDateField(),
            const SizedBox(height: 16),
            _buildTimeFields(),
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
                setState(() {
                  _bobinesUtilisees = bobines;
                  _updateBobineCost(); // Mettre à jour le coût quand les bobines changent
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Section Consommation & Coûts
            Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: const Color(0xFFF5F5F5), // Colors.grey[100]
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFFE0E0E0)), // Colors.grey[300]
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Énergie & Coûts',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _consommationController,
                            decoration: const InputDecoration(
                              labelText: 'Conso. (kWh)',
                              isDense: true,
                              suffixText: 'kWh',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => _updateElectricityCost(),
                            validator: (value) {
                                if (value == null || value.isEmpty) return 'Requis';
                                return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: 'Le taux de $_electricityRate FCFA/kWh est configuré dans les paramètres',
                          child: const Icon(Icons.info_outline, size: 20, color: Colors.blue),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _coutElectriciteController,
                            decoration: const InputDecoration(
                              labelText: 'Coût Élec.',
                              isDense: true,
                              suffixText: 'FCFA',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                                if (value == null || value.isEmpty) return 'Requis';
                                return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _coutBobinesController,
                      decoration: const InputDecoration(
                        labelText: 'Coût Bobines',
                        isDense: true,
                        suffixText: 'FCFA',
                        helperText: 'Calculé selon les prix unitaires en stock',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            _buildQuantiteField(),
            const SizedBox(height: 16),
            _buildEmballagesField(),
            const SizedBox(height: 16),
            _buildNotesField(),
            const SizedBox(height: 16),
            _buildStatusSwitch(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
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

  Widget _buildStatusSwitch() {
    final theme = Theme.of(context);
    final isCompleted = _isTermine;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isCompleted
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.3),
          width: isCompleted ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          SwitchListTile(
            value: _isTermine,
            onChanged: (val) => setState(() => _isTermine = val),
            activeThumbColor: theme.colorScheme.primary,
            title: Row(
              children: [
                Icon(
                  isCompleted ? Icons.lock_outline : Icons.lock_open,
                  color: isCompleted
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  'Finaliser la production',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isCompleted
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                isCompleted
                    ? 'La session sera verrouillée et marquée comme terminée.'
                    : 'La session reste modifiable (En cours).',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : submit,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: _isLoading
          ? const CircularProgressIndicator()
          : Text(
              widget.session == null ? 'Créer la session' : 'Mettre à jour',
            ),
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
    return DateFormatter.formatDate(date);
  }
}
