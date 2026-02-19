import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/bobine_usage.dart';
import '../../domain/entities/bobine_stock_movement.dart';
import '../../domain/entities/production_session.dart';
import '../../domain/repositories/bobine_stock_quantity_repository.dart';
import '../../domain/entities/production_session_status.dart';
import '../../domain/repositories/production_session_repository.dart';
import '../../../audit_trail/domain/services/audit_trail_service.dart';
import '../../domain/repositories/product_repository.dart';
import 'stock_controller.dart';

class ProductionSessionController {
  ProductionSessionController(
    this._repository,
    this._stockController,
    this._bobineStockQuantityRepository,
    this._productRepository,
    this._auditTrailService,
  );

  final ProductionSessionRepository _repository;
  final StockController _stockController;
  final BobineStockQuantityRepository _bobineStockQuantityRepository;
  final ProductRepository _productRepository;
  final AuditTrailService _auditTrailService;

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
    // Calculer le coût des bobines (uniquement les nouvelles)
    final coutBobines = await _calculerCoutBobinesNouvelles(
      bobinesUtilisees: session.bobinesUtilisees,
      sessionId: session.id,
      estNouvelleSession: true,
      sessionExistante: null,
    );

    final sessionAvecCout = session.copyWith(
      coutBobines: session.coutBobines ?? coutBobines,
    );

    final savedSession = await _repository.createSession(sessionAvecCout);

    // Audit Log
    try {
      await _auditTrailService.logAction(
        enterpriseId: savedSession.enterpriseId,
        userId: savedSession.createdBy ?? 'unknown',
        module: 'eau_minerale',
        action: 'create_production_session',
        entityId: savedSession.id,
        entityType: 'production_session',
        metadata: {
          'status': savedSession.status.name,
          'date': savedSession.date.toIso8601String(),
        },
      );
    } catch (e) {
      AppLogger.error('Failed to log production session audit', error: e);
    }

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

    // Calculer le coût des bobines (uniquement les nouvelles)
    final coutBobines = await _calculerCoutBobinesNouvelles(
      bobinesUtilisees: session.bobinesUtilisees,
      sessionId: session.id,
      estNouvelleSession: false,
      sessionExistante: sessionExistante,
    );

    final sessionAvecCout = session.copyWith(
      coutBobines: session.coutBobines ?? coutBobines,
    );

    final savedSession = await _repository.updateSession(sessionAvecCout);

    // Audit Log for Completion
    if (savedSession.status == ProductionSessionStatus.completed &&
        sessionExistante?.status != ProductionSessionStatus.completed) {
      try {
        await _auditTrailService.logAction(
          enterpriseId: savedSession.enterpriseId,
          userId: savedSession.updatedBy ?? savedSession.createdBy ?? 'unknown',
          module: 'eau_minerale',
          action: 'finalize_production_session',
          entityId: savedSession.id,
          entityType: 'production_session',
          metadata: {
            'quantiteProduite': savedSession.quantiteProduite,
          },
        );
      } catch (e) {
        AppLogger.error('Failed to log session finalization audit', error: e);
      }
    }

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
        'Vérification bobine: ${bobineUsage.bobineType} sur machine ${bobineUsage.machineId} (UsageID: ${bobineUsage.id})',
        name: 'eau_minerale.production',
      );

      // ÉTAPE 0: Ignorer les bobines explicitement marquées comme réutilisées
      // (Sécurité supplémentaire en plus du check de mouvement)
      if (bobineUsage.isReused) {
        AppLogger.debug(
          'Bobine marquée comme réutilisée (UsageID: ${bobineUsage.id}) - pas de décrémentation',
          name: 'eau_minerale.production',
        );
        bobinesReutilisees++;
        continue;
      }

      // ÉTAPE 1: Vérifier si cette bobine a DEJA été décrémentée du stock.
      // Un mouvement avec le même bobineUsageId indique que le stock a déjà été réduit pour ce rouleau physique.
      final aDejaMouvement = await _verifierMouvementParUsageId(
        bobineType: bobineUsage.bobineType,
        usageId: bobineUsage.id,
      );

      if (aDejaMouvement) {
        AppLogger.debug(
          'Mouvement trouvé pour cet UsageID (${bobineUsage.id}) - pas de décrémentation supplémentaire',
          name: 'eau_minerale.production',
        );
        bobinesAvecMouvementRecent++;
        continue;
      }

      // ÉTAPE 2: Nouvelle bobine (ou première fois qu'on la voit sans mouvement enregistré)
      // Décrémenter le stock pour cette machine
      AppLogger.debug(
        'DÉCRÉMENTATION du stock pour UsageID: ${bobineUsage.id}',
        name: 'eau_minerale.production',
      );
      try {
        await _stockController.recordBobineExit(
          bobineType: bobineUsage.bobineType,
          quantite: 1,
          productionId: sessionId,
          machineId: bobineUsage.machineId,
          bobineUsageId: bobineUsage.id,
          notes: 'Installation en production',
        );
        AppLogger.debug(
          'Stock décrémenté avec succès pour UsageID ${bobineUsage.id}',
          name: 'eau_minerale.production',
        );
        bobinesDecrimentees++;
      } catch (e, stackTrace) {
        AppLogger.error(
          'ERREUR lors de la décrémentation pour UsageID ${bobineUsage.id}: $e',
          name: 'eau_minerale.production',
          error: e,
          stackTrace: stackTrace,
        );
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

  /// Vérifie si une bobine a déjà un mouvement de sortie pour un UsageID donné.
  /// C'est la méthode la plus robuste pour éviter les doubles décrémentations.
  Future<bool> _verifierMouvementParUsageId({
    required String bobineType,
    required String usageId,
  }) async {
    try {
      final stock = await _bobineStockQuantityRepository.fetchByType(bobineType);
      if (stock == null) return false;

      // On cherche dans TOUS les mouvements de ce stock
      final mouvements = await _bobineStockQuantityRepository.fetchMovements(
        bobineStockId: stock.id,
      );

      // Si un mouvement de sortie avec cet UsageID existe déjà, c'est que le stock a été déduit
      return mouvements.any(
        (m) =>
            m.type == BobineMovementType.sortie &&
            m.bobineUsageId == usageId,
      );
    } catch (e) {
      AppLogger.error('Erreur lors de la vérification par UsageID: $e', error: e);
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

  /// Calcule le coût total des nouvelles bobines installées dans cette session.
  Future<int> _calculerCoutBobinesNouvelles({
    required List<BobineUsage> bobinesUtilisees,
    required String sessionId,
    required bool estNouvelleSession,
    ProductionSession? sessionExistante,
  }) async {
    int totalCout = 0;

    // Récupérer toutes les sessions pour vérifier quelles bobines ont déjà été utilisées
    final toutesSessions = await _repository.fetchSessions();
    final sessionsTriees = toutesSessions.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final bobinesNonFiniesParMachine = <String, BobineUsage>{};
    final bobinesDejaUtiliseesParMachine = <String, List<BobineUsage>>{};

    for (final session in sessionsTriees) {
      if (session.id == sessionId) continue;
      for (final bobineUsage in session.bobinesUtilisees) {
        if (!bobinesDejaUtiliseesParMachine.containsKey(bobineUsage.machineId)) {
          bobinesDejaUtiliseesParMachine[bobineUsage.machineId] = [];
        }
        bobinesDejaUtiliseesParMachine[bobineUsage.machineId]!.add(bobineUsage);
        if (!bobineUsage.estFinie) {
          if (!bobinesNonFiniesParMachine.containsKey(bobineUsage.machineId)) {
            bobinesNonFiniesParMachine[bobineUsage.machineId] = bobineUsage;
          }
        }
      }
    }

    final skipQuota = <String, int>{};
    if (!estNouvelleSession && sessionExistante != null) {
      for (final b in sessionExistante.bobinesUtilisees) {
        final key = '${b.machineId}|${b.bobineType}';
        skipQuota[key] = (skipQuota[key] ?? 0) + 1;
      }
      // Si c'est une mise à jour, on part du coût existant (ou 0 si on veut recalculer tout proprement)
      // On va tout recalculer pour être sûr.
    }

    for (final bobineUsage in bobinesUtilisees) {
      // Ignorer si déjà en session (déjà compté)
      if (!estNouvelleSession && sessionExistante != null) {
        final key = '${bobineUsage.machineId}|${bobineUsage.bobineType}';
        final quota = skipQuota[key] ?? 0;
        if (quota > 0) {
          skipQuota[key] = quota - 1;
          continue;
        }
      }

      // Vérifier si réutilisée
      final bobineNonFinieExistante = bobinesNonFiniesParMachine[bobineUsage.machineId];
      final estBobineNonFinieReutilisee = bobineNonFinieExistante != null &&
          bobineNonFinieExistante.bobineType == bobineUsage.bobineType &&
          bobineNonFinieExistante.dateInstallation.isAtSameMomentAs(bobineUsage.dateInstallation);

      if (estBobineNonFinieReutilisee) continue;

      // Vérifier si mouvement récent (déjà décrémentée → nouvelle)
      // Pour le coût, on doit quand même compter si c'est une nouvelle installation
      
      // Nouvelle bobine -> chercher le prix
      if (bobineUsage.productId != null) {
        try {
          final product = await _productRepository.getProduct(bobineUsage.productId!);
          if (product != null) {
            totalCout += product.unitPrice.toInt();
          }
        } catch (e) {
          AppLogger.error('Erreur lors de la récupération du prix pour ${bobineUsage.bobineType}', error: e);
        }
      }
    }

    return totalCout;
  }
}
