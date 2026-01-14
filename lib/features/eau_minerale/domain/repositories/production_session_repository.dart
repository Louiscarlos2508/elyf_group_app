import '../entities/production_session.dart';

/// Repository pour gérer les sessions de production.
abstract class ProductionSessionRepository {
  /// Récupère toutes les sessions de production.
  Future<List<ProductionSession>> fetchSessions({
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
}
