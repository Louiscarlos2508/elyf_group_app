import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/machine_material_usage.dart';
import '../../domain/entities/production_day.dart';
import '../../domain/entities/production_session.dart';
import '../../domain/services/production_session_builder.dart';
import '../../domain/services/production_session_status_calculator.dart';
import '../../domain/services/validation/production_validation_service.dart';
import 'production_session_form_steps/production_session_form_actions.dart';
import 'production_session_form_steps/production_session_form_dialogs.dart';
import 'production_session_form_steps/production_session_form_helpers.dart';
import 'production_session_form_steps/step_startup.dart';
import 'production_session_form_steps/step_production.dart';
import 'production_session_form_steps/step_finalization.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/notification_service.dart';

/// Formulaire de session de production divisé en étapes.
class ProductionSessionFormSteps extends ConsumerStatefulWidget {
  const ProductionSessionFormSteps({
    super.key,
    this.session,
    required this.currentStep,
    required this.onStepChanged,
  });

  final ProductionSession? session;
  final int currentStep;
  final ValueChanged<int> onStepChanged;

  @override
  ConsumerState<ProductionSessionFormSteps> createState() =>
      ProductionSessionFormStepsState();
}

class ProductionSessionFormStepsState
    extends ConsumerState<ProductionSessionFormSteps> {
  final _formKey = GlobalKey<FormState>();
  final _indexCompteurInitialController =
      TextEditingController(); // kWh au démarrage
  final _indexCompteurFinalController = TextEditingController(); // kWh à la fin
  final _consommationController = TextEditingController();
  final _quantiteController = TextEditingController();
  final _emballagesController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  DateTime _heureDebut = DateTime.now();
  List<String> _machinesSelectionnees = [];
  List<MachineMaterialUsage> _machineMaterials = [];
  List<ProductionDay> _productionDays = [];
  bool _isSavingDraft = false;
  String? _createdSessionId;
  Map<String, MachineMaterialUsage> _machinesAvecMatiereNonFinie = {};

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
    _indexCompteurInitialController.text =
        session.indexCompteurInitialKwh?.toString() ?? '';
    _indexCompteurFinalController.text =
        session.indexCompteurFinalKwh?.toString() ?? '';
    _consommationController.text = session.consommationCourant.toString();
    _quantiteController.text = session.quantiteProduite.toString();
    _emballagesController.text = session.emballagesUtilises?.toString() ?? '';
    _notesController.text = session.notes ?? '';
    _machinesSelectionnees = List.from(session.machinesUtilisees);
    _machineMaterials = List.from(session.machineMaterials);
    _productionDays = List.from(session.productionDays);
  }

  /// Vérifie l'état de chaque machine sélectionnée et charge les matières appropriées.
  Future<void> _chargerMatieresNonFinies() async {
    await ProductionSessionFormActions.chargerMatieresNonFinies(
      ref: ref,
      machinesSelectionnees: _machinesSelectionnees,
      onMaterialsChanged: (materials) =>
          setState(() => _machineMaterials = materials),
      onMachinesAvecMatiereChanged: (machines) =>
          setState(() => _machinesAvecMatiereNonFinie = machines),
      materialsExistants: _machineMaterials,
    );
  }

  @override
  void dispose() {
    _indexCompteurInitialController.dispose();
    _indexCompteurFinalController.dispose();
    _consommationController.dispose();
    _quantiteController.dispose();
    _emballagesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int? get _indexCompteurInitialKwh =>
      ProductionSessionFormHelpers.parseIndexCompteur(
        _indexCompteurInitialController.text,
      );
  int? get _indexCompteurFinalKwh =>
      ProductionSessionFormHelpers.parseIndexCompteur(
        _indexCompteurFinalController.text,
      );

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    final validationError =
        ProductionValidationService.validateMachinesAndMaterials(
          _machinesSelectionnees,
          _machineMaterials,
        );
    if (validationError != null) {
      NotificationService.showWarning(context, validationError);
      return;
    }

    final meterType = await ref.read(electricityMeterTypeProvider.future);
    if (!mounted) return;
    final meterIndexError =
        ProductionValidationService.validateMeterIndex(
          indexText: _indexCompteurInitialController.text,
          meterLabel: meterType.initialLabel,
        );
    if (meterIndexError != null) {
      NotificationService.showWarning(context, meterIndexError);
      return;
    }

    try {
      final config = await ref.read(productionPeriodConfigProvider.future);

      final status = ProductionSessionStatusCalculator.calculateStatus(
        quantiteProduite: int.tryParse(_quantiteController.text) ?? 0,
        heureFin: null,
        heureDebut: _heureDebut,
        machinesUtilisees: _machinesSelectionnees,
        machineMaterials: _machineMaterials,
      );

      final indexInitialKwh = _indexCompteurInitialKwh;
      final indexFinalKwh = _indexCompteurFinalKwh;

      String? sessionId = widget.session?.id ?? _createdSessionId;
      if (sessionId == null || sessionId.isEmpty) {
        sessionId =
            await ProductionSessionFormActions.findExistingUnfinishedSessionId(
              ref: ref,
              currentSessionId: sessionId,
            );
        if (sessionId != null) {
          _createdSessionId = sessionId;
        }
      }

      final enterpriseId = ref.read(activeEnterpriseIdProvider).value ?? '';

      final session = ProductionSessionBuilder.buildFromForm(
        sessionId: sessionId,
        enterpriseId: enterpriseId,
        selectedDate: _selectedDate,
        heureDebut: _heureDebut,
        heureFin: null,
        indexCompteurInitialKwh: indexInitialKwh,
        indexCompteurFinalKwh: indexFinalKwh,
        consommationCourant:
            double.tryParse(
              _consommationController.text.replaceAll(',', '.'),
            ) ??
            0.0,
        machinesUtilisees: _machinesSelectionnees,
        machineMaterials: _machineMaterials,
        quantiteProduite: int.tryParse(_quantiteController.text) ?? 0,
        emballagesUtilises: _emballagesController.text.trim().isNotEmpty
            ? int.tryParse(_emballagesController.text.trim())
            : null,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        status: status,
        productionDays: _productionDays,
        period: config.getPeriodForDate(_selectedDate),
        machineMaterialCost: widget.session?.machineMaterialCost,
        coutEmballages: widget.session?.coutEmballages,
        coutElectricite: widget.session?.coutElectricite,
      );

      final controller = ref.read(productionSessionControllerProvider);
      ProductionSession savedSession;

      if (sessionId == null || sessionId.isEmpty) {
        savedSession = await controller.createSession(session);
        _createdSessionId = savedSession.id;
      } else {
        savedSession = await controller.updateSession(session);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      NotificationService.showInfo(
        context,
        widget.session == null
            ? 'Session créée avec succès'
            : 'Session mise à jour',
      );
    } catch (e) {
      if (!mounted) return;
      NotificationService.showError(context, e.toString());
    }
  }

  Future<void> saveDraft({bool silent = false}) async {
    if (_isSavingDraft) return;
    if (_machinesSelectionnees.isEmpty) {
      return; 
    }

    _isSavingDraft = true;
    try {
      final config = await ref.read(productionPeriodConfigProvider.future);
      final status = ProductionSessionFormActions.calculateStatus(
        ref: ref,
        quantiteProduite: int.tryParse(_quantiteController.text) ?? 0,
        heureFin: widget.session?.heureFin,
        heureDebut: _heureDebut,
        machinesUtilisees: _machinesSelectionnees,
        machineMaterials: _machineMaterials,
      );

      final indexInitialKwh = _indexCompteurInitialKwh;
      String? existingSessionId = widget.session?.id ?? _createdSessionId ?? '';
      if (existingSessionId.isEmpty) {
        existingSessionId =
            await ProductionSessionFormActions.findExistingUnfinishedSessionId(
              ref: ref,
              currentSessionId: existingSessionId,
            );
        if (existingSessionId != null) {
          _createdSessionId = existingSessionId;
        }
      }

      final enterpriseId = ref.read(activeEnterpriseIdProvider).value ?? '';

      final session = ProductionSessionFormActions.buildSession(
        sessionId: existingSessionId,
        enterpriseId: enterpriseId,
        selectedDate: _selectedDate,
        heureDebut: _heureDebut,
        heureFin: widget.session?.heureFin,
        indexCompteurInitialKwh: indexInitialKwh,
        indexCompteurFinalKwh: _indexCompteurFinalKwh,
        consommationCourant:
            double.tryParse(_consommationController.text) ?? 0.0,
        machinesUtilisees: _machinesSelectionnees,
        machineMaterials: _machineMaterials,
        quantiteProduite: int.tryParse(_quantiteController.text) ?? 0,
        emballagesUtilises: _emballagesController.text.trim().isNotEmpty
            ? int.tryParse(_emballagesController.text.trim())
            : null,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        status: status,
        productionDays: _productionDays,
        period: config.getPeriodForDate(_selectedDate),
      );

      final controller = ref.read(productionSessionControllerProvider);

      if (existingSessionId == null || existingSessionId.isEmpty) {
        final createdSession = await controller.createSession(session);
        _createdSessionId = createdSession.id;
        if (mounted && !silent) {
          NotificationService.showInfo(context, 'État sauvegardé');
        }
      } else {
        final sessionToUpdate = session.copyWith(id: existingSessionId);
        await controller.updateSession(sessionToUpdate);
        if (mounted && !silent) {
          NotificationService.showInfo(context, 'État sauvegardé');
        }
      }
    } catch (e) {
      AppLogger.error(
        'Erreur sauvegarde automatique: $e',
        name: 'eau_minerale.production',
        error: e,
      );
    } finally {
      _isSavingDraft = false;
    }
  }

  bool validateCurrentStep() {
    return ProductionSessionFormActions.validateStep(
      formState: _formKey.currentState,
      session: widget.session,
      currentStep: widget.currentStep,
      machinesSelectionnees: _machinesSelectionnees,
      machineMaterials: _machineMaterials,
      indexCompteurInitialKwh: _indexCompteurInitialKwh,
      quantiteText: _quantiteController.text,
      indexCompteurFinalKwh: _indexCompteurFinalKwh,
      consommationText: _consommationController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(key: _formKey, child: _buildCurrentStep());
  }

  Widget _buildCurrentStep() {
    final isEditing = widget.session != null;
    final maxStep = isEditing ? 2 : 0;

    if (widget.currentStep > maxStep) {
      return const SizedBox.shrink();
    }

    switch (widget.currentStep) {
      case 0:
        return StepStartup(
          isEditing: isEditing,
          selectedDate: _selectedDate,
          heureDebut: _heureDebut,
          machinesSelectionnees: _machinesSelectionnees,
          machineMaterials: _machineMaterials,
          machinesAvecMatiereNonFinie: _machinesAvecMatiereNonFinie,
          indexCompteurInitialController: _indexCompteurInitialController,
          onDateChanged: (date) => setState(() => _selectedDate = date),
          onHeureDebutChanged: (heure) => setState(() => _heureDebut = heure),
          onMachinesChanged: (machines) async {
            setState(() => _machinesSelectionnees = machines);
            await _chargerMatieresNonFinies();
          },
          onMaterialsChanged: (materials) =>
              setState(() => _machineMaterials = materials),
          onInstallerMatiere: () =>
              ProductionSessionFormDialogs.showMaterialInstallation(
                context: context,
                ref: ref,
                machinesSelectionnees: _machinesSelectionnees,
                machineMaterials: _machineMaterials,
                onMaterialsChanged: (materials) =>
                    setState(() => _machineMaterials = materials),
              ),
          onSignalerPanne: (context, material, index) =>
              ProductionSessionFormDialogs.showMachineBreakdown(
                context: context,
                ref: ref,
                session: widget.session,
                selectedDate: _selectedDate,
                heureDebut: _heureDebut,
                machinesUtilisees: _machinesSelectionnees,
                machineMaterials: _machineMaterials,
                material: material,
                materialIndex: index,
                onMaterialRemoved: () =>
                    setState(() => _machineMaterials.removeAt(index)),
              ),
          onRetirerMatiere: (index) {
            setState(() => _machineMaterials.removeAt(index));
          },
        );
      case 1:
        return isEditing
            ? StepProduction(
                quantiteController: _quantiteController,
                emballagesController: _emballagesController,
                notesController: _notesController,
                productionDays: _productionDays,
                selectedDate: _selectedDate,
                session: widget.session,
                machinesSelectionnees: _machinesSelectionnees,
                machineMaterials: _machineMaterials,
                machinesAvecMatiereNonFinie: _machinesAvecMatiereNonFinie,
                onProductionDayAdded: (day) {
                  setState(() {
                    final existingIndex = _productionDays.indexWhere(
                      (d) => d.id == day.id,
                    );
                    if (existingIndex != -1) {
                      _productionDays[existingIndex] = day;
                    } else {
                      _productionDays.add(day);
                    }
                  });
                },
                onProductionDayRemoved: (day) {
                  setState(
                    () => _productionDays.removeWhere((d) => d.id == day.id),
                  );
                },
                onMachinesChanged: (machines) async {
                  setState(() => _machinesSelectionnees = machines);
                  await _chargerMatieresNonFinies();
                },
                onMaterialsChanged: (materials) =>
                    setState(() => _machineMaterials = materials),
                onInstallerMatiere: () =>
                    ProductionSessionFormDialogs.showMaterialInstallation(
                  context: context,
                  ref: ref,
                  machinesSelectionnees: _machinesSelectionnees,
                  machineMaterials: _machineMaterials,
                  onMaterialsChanged: (materials) =>
                      setState(() => _machineMaterials = materials),
                ),
                onSignalerPanne: (context, material, index) =>
                    ProductionSessionFormDialogs.showMachineBreakdown(
                  context: context,
                  ref: ref,
                  session: widget.session,
                  selectedDate: _selectedDate,
                  heureDebut: _heureDebut,
                  machinesUtilisees: _machinesSelectionnees,
                  machineMaterials: _machineMaterials,
                  material: material,
                  materialIndex: index,
                  onMaterialRemoved: () =>
                      setState(() => _machineMaterials.removeAt(index)),
                ),
                onRetirerMatiere: (index) {
                  setState(() => _machineMaterials.removeAt(index));
                },
              )
            : const SizedBox.shrink();
      case 2:
        return isEditing
            ? StepFinalization(
                selectedDate: _selectedDate,
                heureDebut: _heureDebut,
                machinesCount: _machinesSelectionnees.length,
                materialsCount: _machineMaterials.length,
                indexCompteurInitialController: _indexCompteurInitialController,
                indexCompteurFinalController: _indexCompteurFinalController,
                consommationController: _consommationController,
                quantiteController: _quantiteController,
                emballagesController: _emballagesController,
              )
            : const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
    }
  }
}
