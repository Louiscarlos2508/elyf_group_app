import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
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
  final _coutEmballagesController = TextEditingController();
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
  int _packagingUnitPrice = 0; // Prix unitaire de l'emballage (sachet)

  @override
  void initState() {
    super.initState();
    _loadConfigurations();
    if (widget.session != null) {
      _initialiserAvecSession(widget.session!);
    }
    
    // Auto-calcul coût électricité lors du changement de consommation
    _consommationController.addListener(_updateElectricityCost);
    
    // Auto-suggestion des emballages lors du changement de quantité produite
    _quantiteController.addListener(_updatePackagingSuggestion);
    
    // Auto-calcul coût emballages lors du changement de quantité d'emballages
    _emballagesController.addListener(_updatePackagingCost);
  }

  void _updatePackagingSuggestion() {
    // Si le champ emballage est vide ou contient la même valeur que la quantité (auto-sync),
    // on met à jour la suggestion.
    final quantiteStr = _quantiteController.text;
    final emballagesStr = _emballagesController.text;
    
    if (emballagesStr.isEmpty || emballagesStr == _previousQuantiteValue) {
       _emballagesController.text = quantiteStr;
    }
    _previousQuantiteValue = quantiteStr;
  }

  String _previousQuantiteValue = '';

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
      
      int packagingPrice = 0;
      for (final stock in stocks.packagingStocks) {
        // Pour l'instant on suppose qu'il y a un type "Emballage" principal
        if (stock.type == 'Emballage' && stock.prixUnitaire != null) {
          packagingPrice = stock.prixUnitaire!;
          break;
        }
      }
      
      if (mounted) {
        setState(() {
          _electricityRate = rate;
          _bobineUnitPrices = prices;
          _packagingUnitPrice = packagingPrice;
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
    _coutEmballagesController.text = (session.coutEmballages ?? 0).toString();
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
      final price = _bobineUnitPrices[bobine.bobineType] ?? 0;
      totalCost += price;
    }
    _coutBobinesController.text = totalCost.toString();
  }
  
  void _updatePackagingCost() {
    final qty = int.tryParse(_emballagesController.text) ?? 0;
    final cost = qty * _packagingUnitPrice;
    if (_coutEmballagesController.text != cost.toString()) {
      _coutEmballagesController.text = cost.toString();
    }
  }

  @override
  void dispose() {
    _consommationController.removeListener(_updateElectricityCost);
    _quantiteController.removeListener(_updatePackagingSuggestion);
    _emballagesController.removeListener(_updatePackagingCost);
    _consommationController.dispose();
    _coutElectriciteController.dispose();
    _coutBobinesController.dispose();
    _quantiteController.dispose();
    _emballagesController.dispose();
    _coutEmballagesController.dispose();
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
      final coutEmb = int.tryParse(_coutEmballagesController.text.replaceAll(RegExp(r'[^0-9]'), ''));

      final enterpriseId = ref.read(activeEnterpriseIdProvider).value ?? '';

      final session = ProductionSessionBuilder.buildFromForm(
        sessionId: widget.session?.id,
        enterpriseId: enterpriseId,
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
        coutEmballages: coutEmb,
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section Timing & Date
            ElyfCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 24,
              backgroundColor: colors.surfaceContainerLow.withValues(alpha: 0.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 18, color: colors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Période & Horaire',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDateField(),
                  const SizedBox(height: 16),
                  _buildTimeFields(),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section Matériel & Bobines
            ElyfCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 24,
              backgroundColor: colors.surfaceContainerLow.withValues(alpha: 0.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.precision_manufacturing_rounded, size: 18, color: colors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Matériel & Ressources',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
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
                        _updateBobineCost();
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section Énergie & Coûts
            ElyfCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 24,
              backgroundColor: colors.primary.withValues(alpha: 0.03),
              borderColor: colors.primary.withValues(alpha: 0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bolt_rounded, size: 20, color: colors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Énergie & Coûts',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                      const Spacer(),
                      Tooltip(
                        message: 'Le taux de $_electricityRate FCFA/kWh est configuré dans les paramètres',
                        child: Icon(Icons.info_outline_rounded, size: 18, color: colors.primary.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _consommationController,
                          decoration: _buildInputDecoration(
                            label: 'Conso. (kWh)',
                            icon: Icons.speed_rounded,
                            suffixText: 'kWh',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => _updateElectricityCost(),
                          validator: (value) => (value == null || value.isEmpty) ? 'Requis' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _coutElectriciteController,
                          decoration: _buildInputDecoration(
                            label: 'Coût Élec.',
                            icon: Icons.payments_rounded,
                            suffixText: 'CFA',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) => (value == null || value.isEmpty) ? 'Requis' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _coutBobinesController,
                    decoration: _buildInputDecoration(
                      label: 'Coût Bobines',
                      icon: Icons.auto_graph_rounded,
                      suffixText: 'CFA',
                      helperText: 'Calculé selon les prix unitaires en stock',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section Production
            ElyfCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 24,
              backgroundColor: colors.surfaceContainerLow.withValues(alpha: 0.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.inventory_rounded, size: 18, color: colors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Résultats de Production',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildQuantiteField(),
                  const SizedBox(height: 16),
                  _buildEmballagesRow(),
                  const SizedBox(height: 16),
                  _buildNotesField(),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildStatusSwitch(),
            const SizedBox(height: 12),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
    String? helperText,
    String? suffixText,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      suffixText: suffixText,
      prefixIcon: Icon(icon, size: 18, color: colors.primary),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.event_rounded, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                'Date de session',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Text(
                  _formatDate(_selectedDate),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Theme.of(context).colorScheme.primary),
              ],
            ),
          ),
        ],
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
      decoration: _buildInputDecoration(
        label: 'Quantité produite (packs)',
        icon: Icons.inventory_2_rounded,
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

  Widget _buildEmballagesRow() {
    // Récupérer le stock d'emballages
    return Consumer(
      builder: (context, ref, child) {
        final stockState = ref.watch(stockStateProvider);
        String? stockHint;
        
        stockState.whenData((data) {
          final packaging = data.packagingStocks.firstOrNull;
          if (packaging != null) {
            stockHint = 'Disponible: ${packaging.quantityLabel}';
          }
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _emballagesController,
                    decoration: _buildInputDecoration(
                      label: 'Emballages (unités)',
                      icon: Icons.inventory_2_outlined,
                      helperText: stockHint ?? 'Auto-suggéré: 1 par pack',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _updatePackagingCost(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _coutEmballagesController,
                    decoration: _buildInputDecoration(
                      label: 'Coût Emb.',
                      icon: Icons.payments_rounded,
                      suffixText: 'CFA',
                    ),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: _buildInputDecoration(
        label: 'Notes',
        icon: Icons.note_alt_rounded,
        helperText: 'Observations sur la session',
      ),
      maxLines: 2,
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(
                widget.session == null ? 'CRÉER LA SESSION' : 'METTRE À JOUR',
                style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
              ),
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
