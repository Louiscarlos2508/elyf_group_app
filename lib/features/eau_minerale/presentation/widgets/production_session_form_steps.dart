import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/bobine_usage.dart';
import '../../domain/entities/electricity_meter_type.dart';
import '../../domain/entities/machine.dart';
import '../../domain/entities/production_day.dart';
import '../../domain/entities/production_session.dart';
import '../../domain/entities/production_session_status.dart';
import '../../domain/entities/stock_movement.dart';
import '../screens/sections/production_session_detail_screen.dart'
    show productionSessionDetailProvider;
import 'daily_personnel_form.dart';
import 'bobine_installation_form.dart';
import 'bobine_usage_form_field.dart' show bobineStocksDisponiblesProvider;
import 'machine_breakdown_dialog.dart';
import 'machine_selector_field.dart';
import 'time_picker_field.dart';

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
  /// Pour chaque machine sélectionnée :
  /// - Si la machine a une bobine non finie dans une session précédente → réutiliser (pas de décrémentation)
  /// - Si la machine n'a pas de bobine non finie → installer une nouvelle bobine (décrémentation)
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
      final machinesMap = <String, Machine>{for (var m in machines) m.id: m};
      final bobineStocks = await ref.read(bobineStocksDisponiblesProvider.future);
      
      // Map pour stocker les bobines non finies trouvées par machine
      final Map<String, BobineUsage> bobinesNonFiniesParMachine = {};
      
      // Parcourir TOUTES les sessions de la plus récente à la plus ancienne
      // pour vérifier l'état de chaque machine sélectionnée
      final sessionsTriees = sessions.toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      
      debugPrint('Vérification de l\'état de ${_machinesSelectionnees.length} machines sélectionnées');
      
      // Pour chaque machine sélectionnée, vérifier si elle a une bobine non finie
      for (final machineId in _machinesSelectionnees) {
        // Chercher dans toutes les sessions si cette machine a une bobine non finie
        for (final session in sessionsTriees) {
          // Chercher une bobine non finie sur cette machine
          try {
            final bobineNonFinie = session.bobinesUtilisees.firstWhere(
              (b) => b.machineId == machineId && !b.estFinie,
            );
            
            // Si on trouve une bobine non finie pour cette machine, la stocker et arrêter
            bobinesNonFiniesParMachine[machineId] = bobineNonFinie;
            debugPrint('✓ Machine ${machinesMap[machineId]?.nom ?? machineId} a une bobine non finie: ${bobineNonFinie.bobineType}');
            break; // Une machine ne peut avoir qu'une bobine à la fois
          } catch (_) {
            // Pas de bobine non finie trouvée dans cette session, continuer
          }
        }
      }
      
      debugPrint('Machines avec bobines non finies: ${bobinesNonFiniesParMachine.length}/${_machinesSelectionnees.length}');
      
      // Vérifier que toutes les machines sélectionnées ont été traitées
      for (final machineId in _machinesSelectionnees) {
        if (bobinesNonFiniesParMachine.containsKey(machineId)) {
          final bobine = bobinesNonFiniesParMachine[machineId]!;
          debugPrint('  ✓ Machine ${machinesMap[machineId]?.nom ?? machineId}: bobine ${bobine.bobineType} (non finie)');
        } else {
          debugPrint('  → Machine ${machinesMap[machineId]?.nom ?? machineId}: nouvelle bobine nécessaire');
        }
      }
      
      // Stocker les machines avec bobines non finies pour affichage
      setState(() {
        _machinesAvecBobineNonFinie = bobinesNonFiniesParMachine;
      });

      // Identifier les machines qui ont déjà une bobine dans la liste actuelle
      final machinesAvecBobine = _bobinesUtilisees.map((b) => b.machineId).toSet();
      
      // Construire la nouvelle liste des bobines utilisées
      final nouvellesBobines = <BobineUsage>[];
      
      // Conserver les bobines existantes qui sont toujours sur des machines sélectionnées
      for (final bobineExistante in _bobinesUtilisees) {
        if (_machinesSelectionnees.contains(bobineExistante.machineId)) {
          nouvellesBobines.add(bobineExistante);
        }
      }
      
      // Pour chaque machine sélectionnée, déterminer quelle bobine utiliser
      for (final machineId in _machinesSelectionnees) {
        // Si cette machine a déjà une bobine dans la liste actuelle, on la garde
        if (machinesAvecBobine.contains(machineId)) {
          continue;
        }
        
        final machine = machinesMap[machineId];
        if (machine == null) continue;
        
        // Vérifier l'état de la machine : a-t-elle une bobine non finie ?
        if (bobinesNonFiniesParMachine.containsKey(machineId)) {
          // Machine avec bobine non finie : réutiliser (pas de décrémentation)
          final bobineNonFinie = bobinesNonFiniesParMachine[machineId]!;
          final maintenant = DateTime.now();
          nouvellesBobines.add(bobineNonFinie.copyWith(
            dateInstallation: maintenant,
            heureInstallation: maintenant,
          ));
          debugPrint('→ Machine ${machine.nom}: réutilisation bobine ${bobineNonFinie.bobineType} (non finie)');
        } else if (bobineStocks.isNotEmpty) {
          // Machine sans bobine non finie : installer une nouvelle bobine (décrémentation)
          final bobineStock = bobineStocks.first;
          final maintenant = DateTime.now();
          final nouvelleBobineUsage = BobineUsage(
            bobineType: bobineStock.type,
            machineId: machineId,
            machineName: machine.nom,
            dateInstallation: maintenant,
            heureInstallation: maintenant,
            estInstallee: true,
            estFinie: false,
          );
          nouvellesBobines.add(nouvelleBobineUsage);
          debugPrint('→ Machine ${machine.nom}: nouvelle bobine ${bobineStock.type} (décrémentation nécessaire)');
        }
      }

      // Mettre à jour la liste des bobines utilisées
      setState(() {
        _bobinesUtilisees = nouvellesBobines;
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

  int? get _indexCompteurInitialKwh {
    final value = _indexCompteurInitialController.text.trim();
    if (value.isEmpty) return null;
    // Accepter les décimales et arrondir
    final doubleValue = double.tryParse(value);
    return doubleValue?.round();
  }
  int? get _indexCompteurFinalKwh {
    final value = _indexCompteurFinalController.text.trim();
    if (value.isEmpty) return null;
    // Accepter les nombres avec virgule ou point décimal et arrondir
    final cleanedValue = value.replaceAll(',', '.');
    final doubleValue = double.tryParse(cleanedValue);
    return doubleValue?.round();
  }

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
    // Si quantité produite > 0 et heure fin > heure début, la production est terminée
    final quantite = int.tryParse(_quantiteController.text) ?? 0;
    // Le statut completed sera défini lors de la finalisation avec heureFin
    if (quantite > 0 && widget.session?.heureFin != null) {
      return ProductionSessionStatus.completed;
    }
    
    // Si machines ou bobines sont sélectionnées, la production est en cours
    if (_machinesSelectionnees.isNotEmpty || _bobinesUtilisees.isNotEmpty) {
      return ProductionSessionStatus.inProgress;
    }
    
    // Si heure début est définie et dans le passé, la production est démarrée
    if (_heureDebut.isBefore(DateTime.now())) {
      return ProductionSessionStatus.started;
    }
    
    // Sinon, c'est un brouillon
    return ProductionSessionStatus.draft;
  }


  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: _buildCurrentStep(),
    );
  }

  Widget _buildCurrentStep() {
    // Pour une nouvelle session, on a seulement l'étape 1
    // Pour une session existante, on garde les 3 étapes
    final isEditing = widget.session != null;
    final maxStep = isEditing ? 2 : 0;
    
    if (widget.currentStep > maxStep) {
      return const SizedBox.shrink();
    }
    
    switch (widget.currentStep) {
      case 0:
        return _buildStep1(isEditing: isEditing);
      case 1:
        return isEditing ? _buildStep2() : const SizedBox.shrink();
      case 2:
        return isEditing ? _buildStep3() : const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1({required bool isEditing}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isEditing ? 'Modifier le démarrage' : 'Démarrage de production',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          isEditing
              ? 'Modifiez les informations de démarrage de la session.'
              : 'Configurez la session de production : date, machines, bobines et index initial.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 24),
        _buildDateField(),
        const SizedBox(height: 16),
        _buildTimeFields(),
        const SizedBox(height: 24),
        Text(
          'Machines utilisées',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        MachineSelectorField(
          machinesSelectionnees: _machinesSelectionnees,
          onMachinesChanged: (machines) async {
            setState(() {
              _machinesSelectionnees = machines;
            });
            
            // Charger automatiquement les bobines non finies pour les machines sélectionnées
            await _chargerBobinesNonFinies();
          },
        ),
        // Afficher une alerte si des machines ont des bobines non finies
        if (_machinesAvecBobineNonFinie.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildBobineNonFinieAlert(context),
        ],
        if (_machinesSelectionnees.isEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '⚠️ Au moins une machine est obligatoire',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
        ],
        // Installation des bobines (toujours affichée)
        const SizedBox(height: 24),
        Text(
          'Installation des bobines',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        _buildBobinesInstallationSection(),
        const SizedBox(height: 24),
        Text(
          'Index compteur électrique au démarrage',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        _buildIndexCompteurInitialField(ref),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Production',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enregistrez les quantités produites et les emballages utilisés.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 24),
        _buildQuantiteField(),
        const SizedBox(height: 16),
        _buildEmballagesField(),
        const SizedBox(height: 24),
        _buildPersonnelSection(),
        const SizedBox(height: 24),
        _buildNotesField(),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Finalisation',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enregistrez les index finaux et la consommation pour finaliser la session.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 24),
        _buildIndexCompteurFinalField(ref),
        const SizedBox(height: 16),
        _buildConsommationField(ref),
        const SizedBox(height: 24),
        _buildSummaryCard(ref),
      ],
    );
  }

  Widget _buildSummaryCard(WidgetRef ref) {
    final meterTypeAsync = ref.watch(electricityMeterTypeProvider);
    
    return meterTypeAsync.when(
      data: (meterType) {
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Résumé de la session',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _buildSummaryRow('Date', _formatDate(_selectedDate)),
                _buildSummaryRow('Heure début', _formatTime(_heureDebut)),
                _buildSummaryRow('Machines', '${_machinesSelectionnees.length}'),
                _buildSummaryRow('Bobines', '${_bobinesUtilisees.length}'),
                if (_indexCompteurInitialKwh != null)
                  _buildSummaryRow(
                    meterType.initialLabel,
                    '$_indexCompteurInitialKwh ${meterType.unit}',
                  ),
                if (_indexCompteurFinalKwh != null)
                  _buildSummaryRow(
                    meterType.finalLabel,
                    '$_indexCompteurFinalKwh ${meterType.unit}',
                  ),
                if (_consommationController.text.isNotEmpty)
                  _buildSummaryRow(
                    'Consommation électrique',
                    '${_consommationController.text} ${meterType.unit}',
                  ),
                _buildSummaryRow('Quantité produite',
                    '${_quantiteController.text} packs'),
                if (_emballagesController.text.isNotEmpty)
                  _buildSummaryRow('Emballages',
                      '${_emballagesController.text} packs'),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Erreur de chargement du type de compteur'),
        ),
      ),
    );
  }

  Widget _buildElectricitySummary(WidgetRef ref) {
    final meterTypeAsync = ref.watch(electricityMeterTypeProvider);
    
    return meterTypeAsync.when(
      data: (meterType) {
        return Column(
          children: [
            if (_indexCompteurInitialKwh != null)
              _buildSummaryRow(
                meterType.initialLabel,
                '$_indexCompteurInitialKwh ${meterType.unit}',
              ),
            if (_indexCompteurFinalKwh != null)
              _buildSummaryRow(
                meterType.finalLabel,
                '$_indexCompteurFinalKwh ${meterType.unit}',
              ),
            if (_consommationController.text.isNotEmpty)
              _buildSummaryRow(
                'Consommation électrique',
                '${_consommationController.text} ${meterType.unit}',
              ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) {
        // Fallback si erreur
        return Column(
          children: [
            if (_indexCompteurInitialKwh != null)
              _buildSummaryRow('Index électrique initial', '$_indexCompteurInitialKwh'),
            if (_indexCompteurFinalKwh != null)
              _buildSummaryRow('Index électrique final', '$_indexCompteurFinalKwh'),
            if (_consommationController.text.isNotEmpty)
              _buildSummaryRow('Consommation courant', '${_consommationController.text}'),
          ],
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
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
        // Heure fin sera définie lors de la finalisation de la production
      ],
    );
  }

  Widget _buildIndexCompteurInitialField(WidgetRef ref) {
    final meterTypeAsync = ref.watch(electricityMeterTypeProvider);
    
    return meterTypeAsync.when(
      data: (meterType) {
        return TextFormField(
          controller: _indexCompteurInitialController,
          decoration: InputDecoration(
            labelText: '${meterType.initialLabel} *',
            prefixIcon: const Icon(Icons.bolt),
            helperText: meterType.initialHelperText,
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Requis';
            }
            // Accepter les nombres avec virgule ou point décimal
            final cleanedValue = value.replaceAll(',', '.');
            final doubleValue = double.tryParse(cleanedValue);
            if (doubleValue == null) {
              return 'Nombre invalide';
            }
            if (doubleValue < 0) {
              return 'Le nombre doit être positif';
            }
            return null;
          },
          onChanged: (_) => setState(() {}),
        );
      },
      loading: () => TextFormField(
        decoration: const InputDecoration(
          labelText: 'Chargement...',
          prefixIcon: Icon(Icons.bolt),
        ),
        enabled: false,
      ),
      error: (_, __) => TextFormField(
        decoration: const InputDecoration(
          labelText: 'Index compteur initial *',
          prefixIcon: Icon(Icons.bolt),
        ),
        keyboardType: TextInputType.numberWithOptions(decimal: true),
      ),
    );
  }

  Widget _buildIndexCompteurFinalField(WidgetRef ref) {
    final meterTypeAsync = ref.watch(electricityMeterTypeProvider);
    
    return meterTypeAsync.when(
      data: (meterType) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              meterType.finalLabel,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _indexCompteurFinalController,
              decoration: InputDecoration(
                labelText: '${meterType.finalLabel} *',
                prefixIcon: const Icon(Icons.bolt),
                helperText: meterType.finalHelperText,
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Requis';
                }
                // Accepter les nombres avec virgule ou point décimal
                final cleanedValue = value.replaceAll(',', '.');
                final finalValue = double.tryParse(cleanedValue);
                if (finalValue == null) {
                  return 'Nombre invalide';
                }
                if (finalValue < 0) {
                  return 'Le nombre doit être positif';
                }
                if (_indexCompteurInitialKwh != null) {
                  if (!meterType.isValidRange(_indexCompteurInitialKwh!.toDouble(), finalValue)) {
                    return meterType.validationErrorMessage;
                  }
                }
                return null;
              },
              onChanged: (value) {
                // Calculer automatiquement la consommation si les deux valeurs sont présentes
                if (_indexCompteurInitialKwh != null && value != null && value.isNotEmpty) {
                  // Accepter les nombres avec virgule ou point décimal
                  final cleanedValue = value.replaceAll(',', '.');
                  final finalValue = double.tryParse(cleanedValue);
                  if (finalValue != null) {
                    final consommation = meterType.calculateConsumption(
                      _indexCompteurInitialKwh!.toDouble(),
                      finalValue,
                    );
                    _consommationController.text = consommation.toStringAsFixed(2);
                    setState(() {});
                  }
                }
              },
            ),
          ],
        );
      },
      loading: () => TextFormField(
        decoration: const InputDecoration(
          labelText: 'Chargement...',
          prefixIcon: Icon(Icons.bolt),
        ),
        enabled: false,
      ),
      error: (_, __) => TextFormField(
        controller: _indexCompteurFinalController,
        decoration: const InputDecoration(
          labelText: 'Index compteur final *',
          prefixIcon: Icon(Icons.bolt),
        ),
        keyboardType: TextInputType.numberWithOptions(decimal: true),
      ),
    );
  }


  Widget _buildConsommationField(WidgetRef ref) {
    final meterTypeAsync = ref.watch(electricityMeterTypeProvider);
    
    return meterTypeAsync.when(
      data: (meterType) {
        return TextFormField(
          controller: _consommationController,
          decoration: InputDecoration(
            labelText: 'Consommation électrique (${meterType.unit}) *',
            prefixIcon: const Icon(Icons.bolt),
            helperText: 'Consommation électrique totale de la session',
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Requis';
            }
            // Accepter les nombres avec virgule ou point décimal
            final cleanedValue = value.replaceAll(',', '.');
            final doubleValue = double.tryParse(cleanedValue);
            if (doubleValue == null) {
              return 'Nombre invalide';
            }
            if (doubleValue < 0) {
              return 'Le nombre doit être positif';
            }
            return null;
          },
        );
      },
      loading: () => TextFormField(
        decoration: const InputDecoration(
          labelText: 'Chargement...',
          prefixIcon: Icon(Icons.bolt),
        ),
        enabled: false,
      ),
      error: (_, __) => TextFormField(
        decoration: const InputDecoration(
          labelText: 'Consommation électrique *',
          prefixIcon: Icon(Icons.bolt),
        ),
        keyboardType: TextInputType.numberWithOptions(decimal: true),
      ),
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
        final intValue = int.tryParse(value);
        if (intValue == null || intValue <= 0) {
          return 'Le nombre doit être un entier positif';
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

  /// Affiche une alerte pour informer l'utilisateur des machines avec bobines non finies
  Widget _buildBobineNonFinieAlert(BuildContext context) {
    final theme = Theme.of(context);
    final machines = _machinesAvecBobineNonFinie.keys.toList();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.orange.shade700,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Bobines non finies détectées',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Les machines suivantes ont des bobines non finies qui seront réutilisées au lieu d\'utiliser le stock :',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ...machines.map((machineId) {
            final bobine = _machinesAvecBobineNonFinie[machineId]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.precision_manufacturing,
                    size: 16,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${bobine.machineName}: ${bobine.bobineType}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ces bobines seront réutilisées automatiquement. Le stock ne sera pas décrémenté.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildBobinesInstallationSection() {
    if (_machinesSelectionnees.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Sélectionnez d\'abord les machines dans l\'étape 1',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    // Identifier les machines avec et sans bobine
    final machinesAvecBobine = _bobinesUtilisees.map((b) => b.machineId).toSet();
    final machinesSansBobine = _machinesSelectionnees
        .where((mId) => !machinesAvecBobine.contains(mId))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Bobines installées (${_bobinesUtilisees.length}/${_machinesSelectionnees.length})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (machinesSansBobine.isNotEmpty)
              IntrinsicWidth(
                child: FilledButton.icon(
                  onPressed: () => _installerBobine(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Installer bobine'),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_bobinesUtilisees.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ajoutez ${_machinesSelectionnees.length} bobine(s) (une par machine). Les bobines seront créées automatiquement.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ),
              ],
            ),
          )
        else
          ..._bobinesUtilisees.asMap().entries.map((entry) {
            final index = entry.key;
            final bobine = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text('${index + 1}'),
                ),
                title: Text(bobine.bobineType),
                subtitle: Text(
                  'Machine: ${bobine.machineName}\n'
                  'Installée le: ${_formatDate(bobine.dateInstallation)} à ${_formatTime(bobine.heureInstallation)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.build, color: Colors.orange),
                      tooltip: 'Signaler panne',
                      onPressed: () => _signalerPanne(context, bobine, index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _bobinesUtilisees.removeAt(index);
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
        if (_bobinesUtilisees.length < _machinesSelectionnees.length) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Il manque ${_machinesSelectionnees.length - _bobinesUtilisees.length} bobine(s)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
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

  Widget _buildPersonnelSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPersonnelSectionHeader(),
        const SizedBox(height: 12),
        if (_productionDays.isEmpty)
          _buildPersonnelEmptyState()
        else
          ..._productionDays.map((day) => _buildPersonnelDayCard(day)),
      ],
    );
  }

  Widget _buildPersonnelSectionHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Personnel journalier',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        IntrinsicWidth(
          child: OutlinedButton.icon(
            onPressed: () => _showPersonnelForm(context, _selectedDate),
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('Ajouter'),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonnelEmptyState() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Ajoutez le personnel qui travaillera chaque jour de production',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonnelDayCard(ProductionDay day) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            '${day.nombrePersonnes}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          _formatDate(day.date),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Text(
          '${day.nombrePersonnes} personne${day.nombrePersonnes > 1 ? 's' : ''} • ${day.coutTotalPersonnel} CFA',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, size: 20),
          onPressed: () {
            setState(() {
              _productionDays.removeWhere((d) => d.id == day.id);
            });
          },
        ),
      ),
    );
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

