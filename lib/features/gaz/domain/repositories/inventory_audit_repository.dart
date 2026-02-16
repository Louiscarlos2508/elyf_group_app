
import '../entities/gaz_inventory_audit.dart';

/// Interface pour le repository des audits d'inventaire Gaz.
abstract class GazInventoryAuditRepository {
  /// Récupère l'historique des audits pour une entreprise, trié par date décroissante.
  Future<List<GazInventoryAudit>> getAudits(
    String enterpriseId, {
    String? siteId,
    int? limit,
  });

  /// Observe l'historique des audits en temps réel.
  Stream<List<GazInventoryAudit>> watchAudits(
    String enterpriseId, {
    String? siteId,
  });

  /// Récupère un audit spécifique par ID.
  Future<GazInventoryAudit?> getAuditById(String id);

  /// Enregistre un nouvel audit.
  Future<void> saveAudit(GazInventoryAudit audit);

  /// Supprime un audit (soft delete).
  Future<void> deleteAudit(String id);
}
