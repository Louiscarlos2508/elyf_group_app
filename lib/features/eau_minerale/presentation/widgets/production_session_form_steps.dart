import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/bobine_usage.dart';
import '../../domain/entities/production_day.dart';
import '../../domain/entities/production_session.dart';
import '../../domain/services/production_session_builder.dart';
import '../../domain/services/production_session_status_calculator.dart';
import '../../domain/services/production_session_validation_service.dart';
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
  List<BobineUsage> _bobinesUtilisees = [];
  List<ProductionDay> _productionDays = [];
  bool _isLoading = false;
  bool _isSavingDraft =
      false; // Flag pour éviter les appels multiples simultanés
  String?
  _createdSessionId; // ID de la session créée pour éviter les créations multiples
  Map<String, BobineUsage> _machinesAvecBobineNonFinie =
      {}; // Machines avec bobines non finies

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
    _bobinesUtilisees = List.from(session.bobinesUtilisees);
    _productionDays = List.from(session.productionDays);
  }

  /// Vérifie l'état de chaque machine sélectionnée et charge les bobines appropriées.
  Future<void> _chargerBobinesNonFinies() async {
    await ProductionSessionFormActions.chargerBobinesNonFinies(
      ref: ref,
      machinesSelectionnees: _machinesSelectionnees,
      onBobinesChanged: (bobines) =>
          setState(() => _bobinesUtilisees = bobines),
      onMachinesAvecBobineChanged: (machines) =>
          setState(() => _machinesAvecBobineNonFinie = machines),
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

    // Validation : index compteur initial requis
    final meterType = await ref.read(electricityMeterTypeProvider.future);
    if (!mounted) return;
    final meterIndexError =
        ProductionSessionValidationService.validateMeterIndex(
          indexText: _indexCompteurInitialController.text,
          meterLabel: meterType.initialLabel,
        );
    if (meterIndexError != null) {
      NotificationService.showWarning(context, meterIndexError);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final config = await ref.read(productionPeriodConfigProvider.future);

      // Calculer le statut basé sur les données disponibles
      final status = ProductionSessionStatusCalculator.calculateStatus(
        quantiteProduite: int.tryParse(_quantiteController.text) ?? 0,
        heureFin: null,
        heureDebut: _heureDebut,
        machinesUtilisees: _machinesSelectionnees,
        bobinesUtilisees: _bobinesUtilisees,
      );

      // Récupérer l'index compteur initial si disponible
      final indexInitialKwh = _indexCompteurInitialKwh;
      final indexFinalKwh = _indexCompteurFinalKwh;

      // Déterminer l'ID de la session à utiliser
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

      final session = ProductionSessionBuilder.buildFromForm(
        sessionId: sessionId,
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
        bobinesUtilisees: _bobinesUtilisees,
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
      ProductionSession savedSession;

      if (sessionId == null || sessionId.isEmpty) {
        // Créer une nouvelle session seulement si aucune session n'existe
        savedSession = await controller.createSession(session);
        _createdSessionId = savedSession.id; // Stocker l'ID créé

        // Le stock a déjà été décrémenté lors de l'assignation des bobines dans _chargerBobinesNonFinies()
        // Pas besoin de décrémenter à nouveau ici
      } else {
        // Le stock sera géré automatiquement dans updateSession (nouvelles bobines seulement)
        savedSession = await controller.updateSession(session);
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

  /// Sauvegarde l'état actuel comme brouillon (méthode publique pour l'écran parent).
  Future<void> saveDraft() async {
    // Éviter les appels multiples simultanés
    if (_isSavingDraft) return;
    if (_machinesSelectionnees.isEmpty)
      return; // Pas de sauvegarde si pas de machines

    _isSavingDraft = true;
    try {
      final config = await ref.read(productionPeriodConfigProvider.future);
      final status = ProductionSessionFormActions.calculateStatus(
        ref: ref,
        quantiteProduite: int.tryParse(_quantiteController.text) ?? 0,
        heureFin: widget.session?.heureFin,
        heureDebut: _heureDebut,
        machinesUtilisees: _machinesSelectionnees,
        bobinesUtilisees: _bobinesUtilisees,
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

      final session = ProductionSessionFormActions.buildSession(
        sessionId: existingSessionId,
        selectedDate: _selectedDate,
        heureDebut: _heureDebut,
        heureFin: widget.session?.heureFin,
        indexCompteurInitialKwh: indexInitialKwh,
        indexCompteurFinalKwh: _indexCompteurFinalKwh,
        consommationCourant:
            double.tryParse(_consommationController.text) ?? 0.0,
        machinesUtilisees: _machinesSelectionnees,
        bobinesUtilisees: _bobinesUtilisees,
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
        // Créer une nouvelle session comme brouillon seulement si aucune session n'existe
        final createdSession = await controller.createSession(session);
        _createdSessionId =
            createdSession.id; // Stocker l'ID pour les prochaines sauvegardes
        if (mounted) {
          NotificationService.showInfo(context, 'État sauvegardé');
        }
      } else {
        // Mettre à jour la session existante (soit widget.session, soit _createdSessionId, soit session trouvée)
        final sessionToUpdate = session.copyWith(id: existingSessionId);
        await controller.updateSession(sessionToUpdate);
        // Ne pas afficher de message pour les sauvegardes automatiques silencieuses
      }
      // Invalider le provider pour rafraîchir la liste
      ref.invalidate(productionSessionsStateProvider);
    } catch (e) {
      // Ignorer les erreurs de sauvegarde automatique silencieusement
      debugPrint('Erreur sauvegarde automatique: $e');
    } finally {
      _isSavingDraft = false;
    }
  }

  /// Valide l'étape actuelle du formulaire.
  bool validateCurrentStep() {
    return ProductionSessionFormActions.validateStep(
      formState: _formKey.currentState,
      session: widget.session,
      currentStep: widget.currentStep,
      machinesSelectionnees: _machinesSelectionnees,
      bobinesUtilisees: _bobinesUtilisees,
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
          bobinesUtilisees: _bobinesUtilisees,
          machinesAvecBobineNonFinie: _machinesAvecBobineNonFinie,
          indexCompteurInitialController: _indexCompteurInitialController,
          onDateChanged: (date) => setState(() => _selectedDate = date),
          onHeureDebutChanged: (heure) => setState(() => _heureDebut = heure),
          onMachinesChanged: (machines) async {
            setState(() => _machinesSelectionnees = machines);
            await _chargerBobinesNonFinies();
          },
          onBobinesChanged: (bobines) =>
              setState(() => _bobinesUtilisees = bobines),
          onInstallerBobine: () =>
              ProductionSessionFormDialogs.showBobineInstallation(
                context: context,
                ref: ref,
                machinesSelectionnees: _machinesSelectionnees,
                bobinesUtilisees: _bobinesUtilisees,
                onBobinesChanged: (bobines) =>
                    setState(() => _bobinesUtilisees = bobines),
              ),
          onSignalerPanne: (context, bobine, index) =>
              ProductionSessionFormDialogs.showMachineBreakdown(
                context: context,
                ref: ref,
                session: widget.session,
                selectedDate: _selectedDate,
                heureDebut: _heureDebut,
                machinesUtilisees: _machinesSelectionnees,
                bobinesUtilisees: _bobinesUtilisees,
                bobine: bobine,
                bobineIndex: index,
                onBobineRemoved: () =>
                    setState(() => _bobinesUtilisees.removeAt(index)),
              ),
          onRetirerBobine: (index) {
            setState(() => _bobinesUtilisees.removeAt(index));
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
                bobinesUtilisees: _bobinesUtilisees,
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
              )
            : const SizedBox.shrink();
      case 2:
        return isEditing
            ? StepFinalization(
                selectedDate: _selectedDate,
                heureDebut: _heureDebut,
                machinesCount: _machinesSelectionnees.length,
                bobinesCount: _bobinesUtilisees.length,
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
