import '../entities/production_session.dart';
import '../entities/machine_material_usage.dart';

/// Repository pour gérer les sessions de production.
abstract class ProductionSessionRepository {
  /// Récupère toutes les sessions de production.
  Future<List<ProductionSession>> fetchSessions({
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Observe les sessions de production.
  Stream<List<ProductionSession>> watchSessions({
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Récupère une session par son ID.
  Future<ProductionSession?> fetchSessionById(String id);

  /// Crée une nouvelle session de production.
  Future<ProductionSession> createSession(ProductionSession session);

  /// Met à jour une session de production.
  Future<ProductionSession> updateSession(ProductionSession session);

  /// Supprime une session de production.
  Future<void> deleteSession(String id);

  /// Récupère la dernière matière installée sur une machine qui n'est pas encore marquée comme finie.
  /// Utilisé pour optimiser la décrémentation des stocks sans charger tout l'historique en mémoire.
  Future<MachineMaterialUsage?> fetchLastUnfinishedMaterialForMachine(String machineId);
}
