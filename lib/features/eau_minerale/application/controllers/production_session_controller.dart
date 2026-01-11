import 'package:flutter/foundation.dart';

import '../../domain/entities/bobine_usage.dart';
import '../../domain/entities/bobine_stock_movement.dart';
import '../../domain/entities/production_session.dart';
import '../../domain/repositories/bobine_stock_quantity_repository.dart';
import '../../domain/repositories/production_session_repository.dart';
import 'stock_controller.dart';

class ProductionSessionController {
  ProductionSessionController(
    this._repository,
    this._stockController,
    this._bobineStockQuantityRepository,
  );

  final ProductionSessionRepository _repository;
  final StockController _stockController;
  final BobineStockQuantityRepository _bobineStockQuantityRepository;

  Future<List<ProductionSession>> fetchSessions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _repository.fetchSessions(
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<ProductionSession?> fetchSessionById(String id) async {
    return _repository.fetchSessionById(id);
  }

  /// Crée une session et décrémente le stock pour les nouvelles bobines.
  Future<ProductionSession> createSession(ProductionSession session) async {
    final savedSession = await _repository.createSession(session);
    
    // Décrémenter le stock pour les bobines nouvelles (pas réutilisées)
    await _decrementerStockBobinesNouvelles(
      bobinesUtilisees: savedSession.bobinesUtilisees,
      sessionId: savedSession.id,
      estNouvelleSession: true,
      sessionExistante: null,
    );
    
    return savedSession;
  }

  /// Met à jour une session et gère le stock des bobines (ajout/suppression).
  Future<ProductionSession> updateSession(ProductionSession session) async {
    // Récupérer la session existante pour comparer
    final sessionExistante = await _repository.fetchSessionById(session.id);
    
    final savedSession = await _repository.updateSession(session);
    
    // Gérer le stock des bobines (décrémenter nouvelles, mais pas les réutilisées)
    await _decrementerStockBobinesNouvelles(
      bobinesUtilisees: savedSession.bobinesUtilisees,
      sessionId: savedSession.id,
      estNouvelleSession: false,
      sessionExistante: sessionExistante,
    );
    
    return savedSession;
  }

  /// Décrémente le stock uniquement pour les bobines nouvelles (pas déjà utilisées).
  /// Les bobines réutilisées (non finies) ne doivent pas être décrémentées à nouveau.
  /// Les bobines déjà décrémentées lors de l'installation ne doivent pas être décrémentées à nouveau.
  Future<void> _decrementerStockBobinesNouvelles({
    required List<BobineUsage> bobinesUtilisees,
    required String sessionId,
    required bool estNouvelleSession,
    ProductionSession? sessionExistante,
  }) async {
    debugPrint('=== Décrémentation stock bobines pour session $sessionId ===');
    debugPrint('Nombre de bobines à vérifier: ${bobinesUtilisees.length}');
    
    // Récupérer toutes les sessions pour vérifier quelles bobines ont déjà été utilisées
    final toutesSessions = await _repository.fetchSessions();
    
    // Créer un map machineId -> BobineUsage pour les bobines déjà utilisées
    // IMPORTANT: On stocke l'objet complet pour préserver toutes les informations
    // On trie les sessions de la plus récente à la plus ancienne pour prendre la bobine la plus récente
    final sessionsTriees = toutesSessions.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    
    // Map pour stocker les bobines non finies (réutilisables) par machine
    final bobinesNonFiniesParMachine = <String, BobineUsage>{};
    // Map pour stocker toutes les bobines déjà utilisées (finies ou non) par machine
    // IMPORTANT: On stocke une LISTE de bobines pour chaque machine car une machine peut avoir
    // plusieurs bobines du même type (ex: une finie puis une nouvelle non finie)
    final bobinesDejaUtiliseesParMachine = <String, List<BobineUsage>>{};
    
    // Parcourir les sessions de la plus récente à la plus ancienne
    // pour s'assurer qu'on prend la bobine la plus récente pour chaque machine
    for (final session in sessionsTriees) {
      // Exclure la session actuelle de la vérification
      if (session.id == sessionId) continue;
      
      for (final bobineUsage in session.bobinesUtilisees) {
        // Ajouter cette bobine à la liste des bobines déjà utilisées sur cette machine
        if (!bobinesDejaUtiliseesParMachine.containsKey(bobineUsage.machineId)) {
          bobinesDejaUtiliseesParMachine[bobineUsage.machineId] = [];
        }
        bobinesDejaUtiliseesParMachine[bobineUsage.machineId]!.add(bobineUsage);
        debugPrint('Bobine déjà utilisée trouvée: ${bobineUsage.bobineType} sur machine ${bobineUsage.machineId} (session ${session.date}, finie: ${bobineUsage.estFinie})');
        
        // Seulement les bobines non finies sont considérées comme "réutilisables"
        // Ces bobines ont déjà été décrémentées lors de leur première installation
        if (!bobineUsage.estFinie) {
          // IMPORTANT: Ne stocker que si cette machine n'a pas encore de bobine non finie
          // Cela garantit qu'on prend la bobine la plus récente (car on parcourt de la plus récente à la plus ancienne)
          if (!bobinesNonFiniesParMachine.containsKey(bobineUsage.machineId)) {
            bobinesNonFiniesParMachine[bobineUsage.machineId] = bobineUsage;
            debugPrint('Bobine non finie trouvée: ${bobineUsage.bobineType} sur machine ${bobineUsage.machineId} (session ${session.date})');
          } else {
            debugPrint('Machine ${bobineUsage.machineId} a déjà une bobine non finie plus récente, ignorée');
          }
        }
      }
    }
    
    debugPrint('Total machines avec bobines non finies détectées: ${bobinesNonFiniesParMachine.length}');
    final totalBobinesDejaUtilisees = bobinesDejaUtiliseesParMachine.values.fold<int>(0, (sum, list) => sum + list.length);
    debugPrint('Total bobines déjà utilisées (toutes): $totalBobinesDejaUtilisees');
    
    // Si on met à jour une session, exclure les bobines de la session existante
    // (car on veut décrémenter seulement les nouvelles ajoutées)
    if (!estNouvelleSession && sessionExistante != null) {
      for (final bobineUsage in sessionExistante.bobinesUtilisees) {
        // Retirer de la liste car ce sont des bobines de cette session
        bobinesNonFiniesParMachine.remove(bobineUsage.machineId);
        bobinesDejaUtiliseesParMachine.remove(bobineUsage.machineId);
      }
    }
    
    debugPrint('Bobines non finies par machine: ${bobinesNonFiniesParMachine.length}');
    debugPrint('Bobines à traiter: ${bobinesUtilisees.length}');
    for (final bobineUsage in bobinesUtilisees) {
      debugPrint('  - ${bobineUsage.bobineType} sur machine ${bobineUsage.machineId}');
    }
    
    // Traiter CHAQUE bobine individuellement
    int bobinesDecrimentees = 0;
    int bobinesReutilisees = 0;
    int bobinesAvecMouvementRecent = 0;
    
    for (final bobineUsage in bobinesUtilisees) {
      debugPrint('\n--- Vérification bobine: ${bobineUsage.bobineType} sur machine ${bobineUsage.machineId} ---');
      
      // ÉTAPE 1: Vérifier si cette machine a une bobine non finie du même type
      // Si oui, c'est une bobine réutilisée qui a déjà été décrémentée lors de sa première installation
      final bobineNonFinieExistante = bobinesNonFiniesParMachine[bobineUsage.machineId];
      final estBobineNonFinieReutilisee = bobineNonFinieExistante != null && 
                                          bobineNonFinieExistante.bobineType == bobineUsage.bobineType;
      
      if (estBobineNonFinieReutilisee) {
        // Bobine non finie réutilisée : ne PAS décrémenter le stock car déjà fait lors de la première installation
        debugPrint('✓ Bobine non finie réutilisée (${bobineNonFinieExistante.bobineType}) - pas de décrémentation');
        bobinesReutilisees++;
        continue;
      }
      
      // ÉTAPE 1b: Vérifier si cette machine a déjà eu des bobines du même type dans des sessions précédentes
      // Si toutes les bobines précédentes de ce type sont finies, alors cette bobine est nouvelle
      // Si une bobine non finie existe mais n'a pas été détectée (cas limite), on évite la décrémentation
      final bobinesPrecedentesSurMachine = bobinesDejaUtiliseesParMachine[bobineUsage.machineId] ?? [];
      final bobinesDuMemeType = bobinesPrecedentesSurMachine.where(
        (b) => b.bobineType == bobineUsage.bobineType,
      ).toList();
      
      if (bobinesDuMemeType.isNotEmpty) {
        // Cette machine a déjà eu des bobines de ce type
        final toutesBobinesFinies = bobinesDuMemeType.every((b) => b.estFinie);
        
        if (!toutesBobinesFinies) {
          // Il y a une bobine non finie de ce type qui n'a pas été détectée dans bobinesNonFiniesParMachine
          // Cela peut arriver si la bobine a été marquée comme finie puis une nouvelle installée dans la même session
          // On évite la décrémentation pour être sûr
          debugPrint('⚠ Bobine du même type non finie trouvée sur cette machine - pas de décrémentation par sécurité');
          bobinesReutilisees++;
          continue;
        }
        // Si toutes les bobines précédentes sont finies, alors cette bobine est nouvelle → on continue pour décrémenter
        debugPrint('→ Toutes les bobines précédentes de ce type sont finies - cette bobine est nouvelle');
      }
      
      // ÉTAPE 2: Vérifier si cette bobine a déjà été décrémentée lors d'une installation
      // en temps réel (via BobineInstallationForm) DANS CETTE SESSION.
      // On vérifie uniquement lors de la mise à jour d'une session (pas lors de la création),
      // car lors de la création, toutes les nouvelles bobines doivent être décrémentées.
      bool aDejaMouvementRecent = false;
      if (!estNouvelleSession) {
        // Seulement lors de la mise à jour : vérifier si la bobine a été installée via le formulaire
        aDejaMouvementRecent = await _verifierMouvementBobineExistant(
          bobineType: bobineUsage.bobineType,
          machineId: bobineUsage.machineId,
          timeWindowMinutes: 5, // Seulement les 5 dernières minutes
        );
      }
      
      if (aDejaMouvementRecent) {
        debugPrint('✓ Mouvement très récent trouvé (installation via formulaire) - pas de décrémentation supplémentaire');
        bobinesAvecMouvementRecent++;
        continue;
      }
      
      // ÉTAPE 3: Nouvelle bobine qui n'a pas encore été décrémentée
      // Décrémenter le stock pour cette machine
      debugPrint('→ NOUVELLE bobine sur machine ${bobineUsage.machineId} - DÉCRÉMENTATION du stock');
      try {
        await _stockController.recordBobineExit(
          bobineType: bobineUsage.bobineType,
          quantite: 1,
          productionId: sessionId,
          machineId: bobineUsage.machineId,
          notes: 'Installation en production',
        );
        debugPrint('✓ Stock décrémenté avec succès pour machine ${bobineUsage.machineId}');
        bobinesDecrimentees++;
      } catch (e) {
        debugPrint('✗ ERREUR lors de la décrémentation pour machine ${bobineUsage.machineId}: $e');
        // Continuer avec les autres bobines même en cas d'erreur
      }
    }
    
    debugPrint('=== Résumé décrémentation stock bobines ===');
    debugPrint('Total bobines traitées: ${bobinesUtilisees.length}');
    debugPrint('Bobines décrémentées: $bobinesDecrimentees');
    debugPrint('Bobines réutilisées (non finies): $bobinesReutilisees');
    debugPrint('Bobines avec mouvement récent: $bobinesAvecMouvementRecent');
    debugPrint('=== Fin décrémentation stock bobines ===\n');
  }

  /// Vérifie si une bobine a déjà un mouvement de sortie pour cette machine.
  /// Utilisé pour éviter les doubles décrémentations lors de la sauvegarde de session.
  /// 
  /// Cette méthode vérifie si une bobine a déjà été décrémentée lors d'une installation
  /// en temps réel (via BobineInstallationForm) en cherchant directement dans les mouvements de bobines.
  /// 
  /// Retourne true si un mouvement de sortie existe déjà pour cette machine et ce type,
  /// ce qui indique que la bobine a déjà été décrémentée et ne doit pas l'être à nouveau.
  /// 
  /// [timeWindowMinutes] : Fenêtre de temps pour chercher les mouvements (par défaut 5 minutes).
  /// Utilisé pour détecter uniquement les installations très récentes via le formulaire.
  Future<bool> _verifierMouvementBobineExistant({
    required String bobineType,
    required String machineId,
    int timeWindowMinutes = 5,
  }) async {
    try {
      // Récupérer le stock pour obtenir l'ID
      final stock = await _bobineStockQuantityRepository.fetchByType(bobineType);
      if (stock == null) {
        debugPrint('Stock non trouvé pour $bobineType - on considère qu\'il n\'y a pas de mouvement');
        return false;
      }
      
      // Récupérer les mouvements très récents (dernières X minutes) pour ce type de bobine
      final maintenant = DateTime.now();
      final limiteTemps = maintenant.subtract(Duration(minutes: timeWindowMinutes));
      
      final mouvements = await _bobineStockQuantityRepository.fetchMovements(
        bobineStockId: stock.id,
        startDate: limiteTemps,
      );
      
      // Chercher un mouvement de sortie pour cette machine et ce type de bobine
      // IMPORTANT: On vérifie que c'est exactement cette machine et ce type
      final mouvementExistant = mouvements.any(
        (m) => m.type == BobineMovementType.sortie &&
               m.bobineReference == bobineType &&
               m.machineId == machineId,
      );
      
      if (mouvementExistant) {
        debugPrint('Mouvement récent trouvé pour $bobineType sur machine $machineId ($timeWindowMinutes min)');
      }
      
      return mouvementExistant;
    } catch (e) {
      debugPrint('Erreur lors de la vérification du mouvement: $e');
      // En cas d'erreur, ne pas bloquer : on décrémente pour être sûr
      return false;
    }
  }

  Future<void> deleteSession(String id) async {
    return _repository.deleteSession(id);
  }
}

