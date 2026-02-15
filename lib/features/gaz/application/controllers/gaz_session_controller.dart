import '../../domain/entities/gaz_session.dart';
import '../../domain/repositories/session_repository.dart';

class GazSessionController {
  GazSessionController({
    required this.sessionRepository,
    required this.enterpriseId,
  });

  final GazSessionRepository sessionRepository;
  final String enterpriseId;

  /// Récupère toutes les sessions.
  Stream<List<GazSession>> watchSessions() {
    return sessionRepository.watchSessions();
  }

  /// Récupère la session pour une date précise.
  Future<GazSession?> getSessionForDate(DateTime date) {
    return sessionRepository.getSessionByDate(date);
  }

  /// Enregistre une clôture de session.
  Future<void> confirmSessionClosure(GazSession session) async {
    await sessionRepository.saveSession(session);
  }

  /// Supprime une session.
  Future<void> deleteSession(String id) async {
    await sessionRepository.deleteSession(id);
  }
}
