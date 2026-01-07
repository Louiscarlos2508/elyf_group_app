import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/bobine_usage.dart';
import '../../domain/entities/machine.dart';
import '../../domain/entities/production_day.dart';
import '../../domain/entities/production_session.dart';
import '../../domain/entities/production_session_status.dart';
import 'bobine_installation_form.dart';
import 'bobine_usage_form_field.dart' show bobineStocksDisponiblesProvider;
import 'daily_personnel_form.dart';
import 'machine_breakdown_dialog.dart';
import 'machine_selector_field.dart';
import 'production_session_form_steps/production_session_form_helpers.dart';
import 'production_session_form_steps/step_startup.dart';
import 'production_session_form_steps/step_production.dart';
import 'production_session_form_steps/step_finalization.dart';

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
  final _indexCompteurInitialController = TextEditingController(); // kWh au démarrage
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
  bool _isSavingDraft = false; // Flag pour éviter les appels multiples simultanés
  String? _createdSessionId; // ID de la session créée pour éviter les créations multiples
  Map<String, BobineUsage> _machinesAvecBobineNonFinie = {}; // Machines avec bobines non finies

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
    _indexCompteurInitialController.text = session.indexCompteurInitialKwh?.toString() ?? '';
    _indexCompteurFinalController.text = session.indexCompteurFinalKwh?.toString() ?? '';
    _consommationController.text = session.consommationCourant.toString();
    _quantiteController.text = session.quantiteProduite.toString();
    _emballagesController.text = session.emballagesUtilises?.toString() ?? '';
    _notesController.text = session.notes ?? '';
    _machinesSelectionnees = List.from(session.machinesUtilisees);
    _bobinesUtilisees = List.from(session.bobinesUtilisees);
    _productionDays = List.from(session.productionDays);
  }

  /// Vérifie l'état de chaque machine sélectionnée et charge les bobines appropriées.
  /// 
  /// Utilise ProductionService pour charger les bobines non finies.
  Future<void> _chargerBobinesNonFinies() async {
    if (_machinesSelectionnees.isEmpty) {
      setState(() {
        _bobinesUtilisees = [];
        _machinesAvecBobineNonFinie = {};
      });
      return;
    }

    try {
      // Récupérer toutes les sessions précédentes pour vérifier l'état des machines
      final sessions = await ref.read(productionSessionsStateProvider.future);
      
      // Récupérer les machines et les stocks pour les noms et types disponibles
      final machines = await ref.read(machinesProvider.future);
      final bobineStocks = await ref.read(bobineStocksDisponiblesProvider.future);
      
      // Utiliser ProductionService pour charger les bobines non finies
      final productionService = ref.read(productionServiceProvider);
      final result = await productionService.chargerBobinesNonFinies(
        machinesSelectionnees: _machinesSelectionnees,
        sessionsPrecedentes: sessions.toList(),
        machines: machines,
        bobineStocksDisponibles: bobineStocks,
        // Bobines are managed separately
      );

      // Mettre à jour la liste des bobines utilisées
      setState(() {
        _bobinesUtilisees = result.bobinesUtilisees;
        _machinesAvecBobineNonFinie = result.machinesAvecBobineNonFinie;
      });
      
      debugPrint('Bobines assignées: ${_bobinesUtilisees.length} pour ${_machinesSelectionnees.length} machines');
    } catch (e) {
      debugPrint('Erreur lors de la vérification de l\'état des machines: $e');
    }
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
    
    // Validation : au moins une machine
    if (_machinesSelectionnees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez au moins une machine')),
      );
      return;
    }
    
    // Validation : nombre de bobines = nombre de machines
    if (_bobinesUtilisees.length != _machinesSelectionnees.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Le nombre de bobines (${_bobinesUtilisees.length}) doit être égal au nombre de machines (${_machinesSelectionnees.length})',
          ),
        ),
      );
      return;
    }
    
    // Validation : index compteur initial requis
    if (_indexCompteurInitialController.text.isEmpty) {
      final meterType = await ref.read(electricityMeterTypeProvider.future);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('L\'${meterType.initialLabel.toLowerCase()} est requis')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final config = await ref.read(productionPeriodConfigProvider.future);
      
      // Calculer le statut basé sur les données disponibles
      final status = _calculateStatus();
      
      // Récupérer l'index compteur initial si disponible
      // Accepter les décimales et arrondir
      final indexInitialKwh = _indexCompteurInitialKwh;
      
      // Accepter les décimales et arrondir
      final indexFinalKwh = _indexCompteurFinalKwh;
      
      // Déterminer l'ID de la session à utiliser
      // Priorité: widget.session?.id > _createdSessionId > vérifier sessions existantes
      String? sessionId = widget.session?.id ?? _createdSessionId;
      
      // Si pas d'ID, vérifier s'il existe déjà une session non terminée
      if (sessionId == null || sessionId.isEmpty) {
        final sessions = await ref.read(productionSessionsStateProvider.future);
        final sessionsNonTerminees = sessions.where(
          (s) {
            final effectiveStatus = s.effectiveStatus;
            return effectiveStatus != ProductionSessionStatus.completed;
          },
        ).toList();
        
        if (sessionsNonTerminees.isNotEmpty) {
          // Utiliser la session existante au lieu d'en créer une nouvelle
          sessionId = sessionsNonTerminees.first.id;
          _createdSessionId = sessionId; // Stocker pour référence future
        }
      }
      
      final session = ProductionSession(
        id: sessionId ?? '',
        date: _selectedDate,
        period: config.getPeriodForDate(_selectedDate),
        heureDebut: _heureDebut,
        heureFin: null, // Sera défini lors de la finalisation
        indexCompteurInitialKwh: indexInitialKwh,
        indexCompteurFinalKwh: indexFinalKwh,
        consommationCourant: double.tryParse(_consommationController.text.replaceAll(',', '.')) ?? 0.0,
        machinesUtilisees: _machinesSelectionnees,
        bobinesUtilisees: _bobinesUtilisees,
        quantiteProduite: int.tryParse(_quantiteController.text) ?? 0,
        quantiteProduiteUnite: 'pack',
        emballagesUtilises: _emballagesController.text.trim().isNotEmpty
            ? int.tryParse(_emballagesController.text.trim())
            : null,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        status: status,
        productionDays: _productionDays,
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

  /// Sauvegarde l'état actuel comme brouillon (méthode publique pour l'écran parent).
  Future<void> saveDraft() async {
    // Éviter les appels multiples simultanés
    if (_isSavingDraft) return;
    if (_machinesSelectionnees.isEmpty) return; // Pas de sauvegarde si pas de machines

    _isSavingDraft = true;
    try {
      final config = await ref.read(productionPeriodConfigProvider.future);
      final status = _calculateStatus();
      // Accepter les décimales et arrondir
      final indexInitialKwh = _indexCompteurInitialKwh;

      // Déterminer l'ID de la session à utiliser
      // Vérifier d'abord si une session a déjà été créée dans cette instance
      final sessionId = widget.session?.id ?? _createdSessionId ?? '';
      
      // Si pas d'ID, vérifier s'il existe déjà une session non terminée
      String? existingSessionId = sessionId;
      if (sessionId.isEmpty) {
        final sessions = await ref.read(productionSessionsStateProvider.future);
        final sessionsNonTerminees = sessions.where(
          (s) {
            final effectiveStatus = s.effectiveStatus;
            return effectiveStatus != ProductionSessionStatus.completed;
          },
        ).toList();
        
        // Si une session non terminée existe, l'utiliser
        if (sessionsNonTerminees.isNotEmpty) {
          existingSessionId = sessionsNonTerminees.first.id;
          _createdSessionId = existingSessionId; // Stocker pour éviter les créations futures
        }
      }
      
      final session = ProductionSession(
        id: existingSessionId ?? '',
        date: _selectedDate,
        period: config.getPeriodForDate(_selectedDate),
        heureDebut: _heureDebut,
        heureFin: widget.session?.heureFin,
        indexCompteurInitialKwh: indexInitialKwh,
        indexCompteurFinalKwh: _indexCompteurFinalKwh,
        consommationCourant: double.tryParse(_consommationController.text) ?? 0.0,
        machinesUtilisees: _machinesSelectionnees,
        bobinesUtilisees: _bobinesUtilisees,
        quantiteProduite: int.tryParse(_quantiteController.text) ?? 0,
        quantiteProduiteUnite: 'pack',
        emballagesUtilises: _emballagesController.text.trim().isNotEmpty
            ? int.tryParse(_emballagesController.text.trim())
            : null,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        status: status,
        productionDays: _productionDays,
      );

      final controller = ref.read(productionSessionControllerProvider);
      
      if (existingSessionId == null || existingSessionId.isEmpty) {
        // Créer une nouvelle session comme brouillon seulement si aucune session n'existe
        final createdSession = await controller.createSession(session);
        _createdSessionId = createdSession.id; // Stocker l'ID pour les prochaines sauvegardes
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('État sauvegardé'),
              duration: Duration(seconds: 2),
            ),
          );
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
    if (!(_formKey.currentState?.validate() ?? false)) {
      return false;
    }
    
    final isEditing = widget.session != null;
    
    switch (widget.currentStep) {
      case 0:
        // Démarrage : date, machines, index initial kWh
        // Pour une nouvelle session, on n'exige pas les bobines (elles seront installées dans le suivi)
        // Pour une session existante, on exige les bobines si on est en mode édition
        if (isEditing) {
          return _machinesSelectionnees.isNotEmpty &&
              _bobinesUtilisees.length == _machinesSelectionnees.length &&
              _indexCompteurInitialKwh != null;
        } else {
          return _machinesSelectionnees.isNotEmpty &&
              _indexCompteurInitialKwh != null;
        }
      case 1:
        // Production : quantité produite (seulement en mode édition)
        return isEditing && _quantiteController.text.isNotEmpty;
      case 2:
        // Finalisation : index final, consommation (seulement en mode édition)
        return isEditing && _indexCompteurFinalKwh != null && _consommationController.text.isNotEmpty;
      default:
        return true;
    }
  }

  /// Calcule le statut de progression basé sur les données saisies
  ProductionSessionStatus _calculateStatus() {
    // Utiliser ProductionService pour calculer le statut
    final productionService = ref.read(productionServiceProvider);
    final quantiteProduite = int.tryParse(_quantiteController.text) ?? 0;
    final heureFin = widget.session?.heureFin;
    
    return productionService.calculateStatus(
      quantiteProduite: quantiteProduite,
      heureFin: heureFin,
      heureDebut: _heureDebut,
      machinesUtilisees: _machinesSelectionnees,
      bobinesUtilisees: _bobinesUtilisees,
    );
  }


  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: _buildCurrentStep(),
    );
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
          onBobinesChanged: (bobines) => setState(() => _bobinesUtilisees = bobines),
          onInstallerBobine: () => _installerBobine(context),
          onSignalerPanne: _signalerPanne,
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
                    final existingIndex = _productionDays.indexWhere((d) => d.id == day.id);
                    if (existingIndex != -1) {
                      _productionDays[existingIndex] = day;
                    } else {
                      _productionDays.add(day);
                    }
                  });
                },
                onProductionDayRemoved: (day) {
                  setState(() => _productionDays.removeWhere((d) => d.id == day.id));
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




  Future<void> _installerBobine(BuildContext context) async {
    // Trouver une machine sans bobine
    final machinesAvecBobine = _bobinesUtilisees.map((b) => b.machineId).toSet();
    final machinesSansBobine = _machinesSelectionnees
        .where((mId) => !machinesAvecBobine.contains(mId))
        .toList();

    if (machinesSansBobine.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Toutes les machines ont une bobine')),
      );
      return;
    }

    // Récupérer les machines
    final machines = await ref.read(machinesProvider.future);
    
    final machine = machines.firstWhere((m) => m.id == machinesSansBobine.first);

    if (!context.mounted) return;
    final result = await showDialog<BobineUsage>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: BobineInstallationForm(
          machine: machine,
          // Le formulaire vérifiera automatiquement s'il y a une bobine non finie à réutiliser
        ),
      ),
    );

    if (result != null && mounted) {
      // Vérifier si cette bobine n'est pas déjà dans la liste (cas de réutilisation)
      final existeDeja = _bobinesUtilisees.any(
        (b) => b.bobineType == result.bobineType && b.machineId == result.machineId,
      );
      
      if (!existeDeja) {
        // Le stock est déjà décrémenté dans BobineInstallationForm pour les nouvelles bobines
        // Les bobines non finie réutilisées n'ont pas besoin de décrément
        setState(() {
          _bobinesUtilisees.add(result);
        });
      }
    }
  }


  void _showPersonnelForm(BuildContext context, DateTime date) {
    // Créer une session temporaire pour le formulaire
    final tempSession = ProductionSession(
      id: widget.session?.id ?? 'temp',
      date: _selectedDate,
      period: 1,
      heureDebut: _heureDebut,
      consommationCourant: 0,
      machinesUtilisees: _machinesSelectionnees,
      bobinesUtilisees: _bobinesUtilisees,
      quantiteProduite: 0,
      quantiteProduiteUnite: 'pack',
      productionDays: _productionDays,
    );

    // Vérifier si un jour existe déjà pour cette date
    ProductionDay? existingDay;
    try {
      existingDay = _productionDays.firstWhere(
        (d) =>
            d.date.year == date.year &&
            d.date.month == date.month &&
            d.date.day == date.day,
      );
    } catch (e) {
      existingDay = null;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: DailyPersonnelForm(
            session: tempSession,
            date: date,
            existingDay: existingDay,
            onSaved: (productionDay) async {
              // Calculer la différence pour gérer les modifications
              int ancienPacksProduits = 0;
              int ancienEmballagesUtilises = 0;
              
              if (existingDay != null) {
                ancienPacksProduits = existingDay.packsProduits;
                ancienEmballagesUtilises = existingDay.emballagesUtilises;
              }
              
              setState(() {
                if (existingDay != null) {
                  final index = _productionDays.indexWhere((d) => d.id == existingDay!.id);
                  if (index != -1) {
                    _productionDays[index] = productionDay;
                  }
                } else {
                  _productionDays.add(productionDay);
                }
              });
              
              // IMPORTANT: Ne pas mettre à jour les stocks ici
              // Les mouvements de stock seront enregistrés UNIQUEMENT lors de la finalisation
              // pour éviter les duplications et garantir un historique cohérent
              // Les modifications des jours de production sont juste sauvegardées dans la session
              
              if (mounted) {
                ref.invalidate(stockStateProvider);
                Navigator.of(context).pop();
              }
            },
          ),
        ),
      ),
    );
  }

  /// Signale une panne de machine et permet de retirer la bobine.
  Future<void> _signalerPanne(
    BuildContext context,
    BobineUsage bobine,
    int index,
  ) async {
    // Créer un objet Machine à partir des infos de la bobine
    final machine = Machine(
      id: bobine.machineId,
      nom: bobine.machineName,
      reference: bobine.machineId,
    );
    
    // Créer une session temporaire pour le dialog
    final tempSession = ProductionSession(
      id: widget.session?.id ?? 'temp',
      date: _selectedDate,
      period: 1,
      heureDebut: _heureDebut,
      consommationCourant: 0,
      machinesUtilisees: _machinesSelectionnees,
      bobinesUtilisees: _bobinesUtilisees,
      quantiteProduite: 0,
      quantiteProduiteUnite: 'pack',
      events: widget.session?.events ?? [],
    );

    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (dialogContext) => MachineBreakdownDialog(
        machine: machine,
        session: tempSession,
        bobine: bobine,
        onPanneSignaled: (event) {
          // Retirer la bobine de la liste si elle a été retirée
          setState(() {
            _bobinesUtilisees.removeAt(index);
          });
          // Invalider les providers pour rafraîchir les données
          ref.invalidate(productionSessionsStateProvider);
          if (widget.session != null) {
            ref.invalidate(productionSessionDetailProvider(widget.session!.id));
          }
        },
      ),
    );
  }

}

