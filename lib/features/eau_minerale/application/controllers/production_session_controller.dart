import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/bobine_usage.dart';
import '../../domain/entities/bobine_stock_movement.dart';
import '../../domain/entities/production_session.dart';
import '../../domain/repositories/bobine_stock_quantity_repository.dart';
import '../../domain/entities/production_session_status.dart';
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
    return _repository.fetchSessions(startDate: startDate, endDate: endDate);
  }

  Stream<List<ProductionSession>> watchSessions({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _repository.watchSessions(startDate: startDate, endDate: endDate);
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
    AppLogger.debug(
      '=== Décrémentation stock bobines pour session $sessionId ===',
      name: 'eau_minerale.production',
    );
    AppLogger.debug(
      'Nombre de bobines à vérifier: ${bobinesUtilisees.length}',
      name: 'eau_minerale.production',
    );

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

      // Note: On inclut les sessions annulées (cancelled) car une bobine installée
      // reste physiquement sur la machine même si la session de travail est annulée.
      // Cela permet de ne pas décompter le stock deux fois lors de la session suivante.

      for (final bobineUsage in session.bobinesUtilisees) {
        // Ajouter cette bobine à la liste des bobines déjà utilisées sur cette machine
        if (!bobinesDejaUtiliseesParMachine.containsKey(
          bobineUsage.machineId,
        )) {
          bobinesDejaUtiliseesParMachine[bobineUsage.machineId] = [];
        }
        bobinesDejaUtiliseesParMachine[bobineUsage.machineId]!.add(bobineUsage);
        AppLogger.debug(
          'Bobine déjà utilisée trouvée: ${bobineUsage.bobineType} sur machine ${bobineUsage.machineId} (session ${session.date}, finie: ${bobineUsage.estFinie})',
          name: 'eau_minerale.production',
        );

        // Seulement les bobines non finies sont considérées comme "réutilisables"
        // Ces bobines ont déjà été décrémentées lors de leur première installation
        if (!bobineUsage.estFinie) {
          // IMPORTANT: Ne stocker que si cette machine n'a pas encore de bobine non finie
          // Cela garantit qu'on prend la bobine la plus récente (car on parcourt de la plus récente à la plus ancienne)
          if (!bobinesNonFiniesParMachine.containsKey(bobineUsage.machineId)) {
            bobinesNonFiniesParMachine[bobineUsage.machineId] = bobineUsage;
            AppLogger.debug(
              'Bobine non finie trouvée: ${bobineUsage.bobineType} sur machine ${bobineUsage.machineId} (session ${session.date})',
              name: 'eau_minerale.production',
            );
          } else {
            AppLogger.debug(
              'Machine ${bobineUsage.machineId} a déjà une bobine non finie plus récente, ignorée',
              name: 'eau_minerale.production',
            );
          }
        }
      }
    }

    AppLogger.debug(
      'Total machines avec bobines non finies détectées: ${bobinesNonFiniesParMachine.length}',
      name: 'eau_minerale.production',
    );
    final totalBobinesDejaUtilisees = bobinesDejaUtiliseesParMachine.values
        .fold<int>(0, (sum, list) => sum + list.length);
    AppLogger.debug(
      'Total bobines déjà utilisées (toutes): $totalBobinesDejaUtilisees',
      name: 'eau_minerale.production',
    );

    // Si on met à jour une session, exclure les bobines de la session existante
    // (car on veut décrémenter seulement les nouvelles ajoutées)
    if (!estNouvelleSession && sessionExistante != null) {
      for (final bobineUsage in sessionExistante.bobinesUtilisees) {
        bobinesNonFiniesParMachine.remove(bobineUsage.machineId);
        bobinesDejaUtiliseesParMachine.remove(bobineUsage.machineId);
      }
    }

    // Quota de bobines à ignorer (déjà dans la session avant mise à jour → déjà décrémentées).
    // Évite double décrément quand on marque "finie" ou qu'on ajoute une nouvelle sur la même machine.
    final skipQuota = <String, int>{};
    if (!estNouvelleSession && sessionExistante != null) {
      for (final b in sessionExistante.bobinesUtilisees) {
        final key = '${b.machineId}|${b.bobineType}';
        skipQuota[key] = (skipQuota[key] ?? 0) + 1;
      }
    }

    AppLogger.debug(
      'Bobines non finies par machine: ${bobinesNonFiniesParMachine.length}',
      name: 'eau_minerale.production',
    );
    AppLogger.debug(
      'Bobines à traiter: ${bobinesUtilisees.length}',
      name: 'eau_minerale.production',
    );
    for (final bobineUsage in bobinesUtilisees) {
      AppLogger.debug(
        'Bobine à traiter: ${bobineUsage.bobineType} sur machine ${bobineUsage.machineId}',
        name: 'eau_minerale.production',
      );
    }

    int bobinesDecrimentees = 0;
    int bobinesReutilisees = 0;
    int bobinesAvecMouvementRecent = 0;
    int bobinesDejaEnSession = 0;

    for (final bobineUsage in bobinesUtilisees) {
      AppLogger.debug(
        'Vérification bobine: ${bobineUsage.bobineType} sur machine ${bobineUsage.machineId}',
        name: 'eau_minerale.production',
      );

      // ÉTAPE 0: Ignorer les bobines déjà présentes avant la mise à jour (déjà décrémentées).
      if (!estNouvelleSession && sessionExistante != null) {
        final key = '${bobineUsage.machineId}|${bobineUsage.bobineType}';
        final quota = skipQuota[key] ?? 0;
        if (quota > 0) {
          skipQuota[key] = quota - 1;
          AppLogger.debug(
            'Bobine déjà en session (${bobineUsage.bobineType} / ${bobineUsage.machineId}) - pas de décrémentation',
            name: 'eau_minerale.production',
          );
          bobinesDejaEnSession++;
          continue;
        }
      }

      // ÉTAPE 1: Vérifier si cette machine a une bobine non finie du même type
      // Si oui, c'est une bobine réutilisée qui a déjà été décrémentée lors de sa première installation
      final bobineNonFinieExistante =
          bobinesNonFiniesParMachine[bobineUsage.machineId];
      final estBobineNonFinieReutilisee =
          bobineNonFinieExistante != null &&
          bobineNonFinieExistante.bobineType == bobineUsage.bobineType &&
          // IMPORTANT: Pour être considérée comme réutilisée, la date d'installation doit être IDENTIQUE.
          // Si la date diffère, cela signifie que c'est une NOUVELLE bobine du même type
          // qui a été installée physiquement (et le formulaire a mis une nouvelle date).
          bobineNonFinieExistante.dateInstallation.isAtSameMomentAs(bobineUsage.dateInstallation);

      if (estBobineNonFinieReutilisee) {
        // Bobine non finie réutilisée : ne PAS décrémenter le stock car déjà fait lors de la première installation
        AppLogger.debug(
          'Bobine non finie réutilisée (${bobineNonFinieExistante.bobineType}) - pas de décrémentation',
          name: 'eau_minerale.production',
        );
        bobinesReutilisees++;
        continue;
      }

      // ÉTAPE 1b: Vérifier si cette machine a déjà eu des bobines du même type dans des sessions précédentes
      // Si toutes les bobines précédentes de ce type sont finies, alors cette bobine est nouvelle
      // Si une bobine non finie existe mais n'a pas été détectée (cas limite), on évite la décrémentation
      final bobinesPrecedentesSurMachine =
          bobinesDejaUtiliseesParMachine[bobineUsage.machineId] ?? [];
      final bobinesDuMemeType = bobinesPrecedentesSurMachine
          .where((b) => b.bobineType == bobineUsage.bobineType)
          .toList();

      if (bobinesDuMemeType.isNotEmpty) {
        // Cette machine a déjà eu des bobines de ce type
        final toutesBobinesFinies = bobinesDuMemeType.every((b) => b.estFinie);

        if (!toutesBobinesFinies) {
          // Il y a une bobine non finie de ce type qui n'a pas été détectée dans bobinesNonFiniesParMachine
          // Cela peut arriver si la bobine a été marquée comme finie puis une nouvelle installée dans la même session
          // On évite la décrémentation pour être sûr
          AppLogger.warning(
            'Bobine du même type non finie trouvée sur cette machine - pas de décrémentation par sécurité',
            name: 'eau_minerale.production',
          );
          bobinesReutilisees++;
          continue;
        }
        // Si toutes les bobines précédentes sont finies, alors cette bobine est nouvelle → on continue pour décrémenter
        AppLogger.debug(
          'Toutes les bobines précédentes de ce type sont finies - cette bobine est nouvelle',
          name: 'eau_minerale.production',
        );
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
        AppLogger.debug(
          'Mouvement très récent trouvé (installation via formulaire) - pas de décrémentation supplémentaire',
          name: 'eau_minerale.production',
        );
        bobinesAvecMouvementRecent++;
        continue;
      }

      // ÉTAPE 3: Nouvelle bobine qui n'a pas encore été décrémentée
      // Décrémenter le stock pour cette machine
      AppLogger.debug(
        'NOUVELLE bobine sur machine ${bobineUsage.machineId} - DÉCRÉMENTATION du stock',
        name: 'eau_minerale.production',
      );
      try {
        await _stockController.recordBobineExit(
          bobineType: bobineUsage.bobineType,
          quantite: 1,
          productionId: sessionId,
          machineId: bobineUsage.machineId,
          notes: 'Installation en production',
        );
        AppLogger.debug(
          'Stock décrémenté avec succès pour machine ${bobineUsage.machineId}',
          name: 'eau_minerale.production',
        );
        bobinesDecrimentees++;
      } catch (e, stackTrace) {
        AppLogger.error(
          'ERREUR lors de la décrémentation pour machine ${bobineUsage.machineId}: $e',
          name: 'eau_minerale.production',
          error: e,
          stackTrace: stackTrace,
        );
        // Continuer avec les autres bobines même en cas d'erreur
      }
    }

    AppLogger.info(
      '=== Résumé décrémentation stock bobines ===',
      name: 'eau_minerale.production',
    );
    AppLogger.info(
      'Total bobines traitées: ${bobinesUtilisees.length}, Décrémentées: $bobinesDecrimentees, Réutilisées: $bobinesReutilisees, Déjà en session: $bobinesDejaEnSession, Avec mouvement récent: $bobinesAvecMouvementRecent',
      name: 'eau_minerale.production',
    );
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
      final stock = await _bobineStockQuantityRepository.fetchByType(
        bobineType,
      );
      if (stock == null) {
        AppLogger.debug(
          'Stock non trouvé pour $bobineType - on considère qu\'il n\'y a pas de mouvement',
          name: 'eau_minerale.production',
        );
        return false;
      }

      // Récupérer les mouvements très récents (dernières X minutes) pour ce type de bobine
      final maintenant = DateTime.now();
      final limiteTemps = maintenant.subtract(
        Duration(minutes: timeWindowMinutes),
      );

      final mouvements = await _bobineStockQuantityRepository.fetchMovements(
        bobineStockId: stock.id,
        startDate: limiteTemps,
      );

      // Chercher un mouvement de sortie pour cette machine et ce type de bobine
      // IMPORTANT: On vérifie que c'est exactement cette machine et ce type
      final mouvementExistant = mouvements.any(
        (m) =>
            m.type == BobineMovementType.sortie &&
            m.bobineReference == bobineType &&
            m.machineId == machineId,
      );

      if (mouvementExistant) {
        AppLogger.debug(
          'Mouvement récent trouvé pour $bobineType sur machine $machineId ($timeWindowMinutes min)',
          name: 'eau_minerale.production',
        );
      }

      return mouvementExistant;
    } catch (e) {
      AppLogger.error(
        'Erreur lors de la vérification du mouvement: $e',
        name: 'eau_minerale.production',
        error: e,
      );
      // En cas d'erreur, ne pas bloquer : on décrémente pour être sûr
      return false;
    }
  }

  Future<void> deleteSession(String id) async {
    return _repository.deleteSession(id);
  }

  /// Annule une session (soft delete) avec un motif.
  /// Si la session avait des bobines installées, elles sont "rendues" au stock.
  Future<void> cancelSession(ProductionSession session, String reason) async {
    AppLogger.info(
      'Annulation de la session ${session.id}. Motif: $reason',
      name: 'eau_minerale.production',
    );

    final cancelledSession = session.copyWith(
      status: ProductionSessionStatus.cancelled,
      cancelReason: reason,
      updatedAt: DateTime.now(),
    );

    await _repository.updateSession(cancelledSession);

    // Note: On ne restaure PAS le stock ici.
    // Selon la règle métier : une bobine installée reste sur la machine même si la session est annulée.
    // Le système de détection de réutilisation (_decrementerStockBobinesNouvelles) continuera
    // de voir cette bobine comme "sur la machine" pour les prochaines sessions,
    // évitant ainsi un double décompte du stock.
  }
}
