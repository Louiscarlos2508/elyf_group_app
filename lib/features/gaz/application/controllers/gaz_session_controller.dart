import '../../domain/entities/gaz_session.dart';
import '../../domain/repositories/session_repository.dart';
import '../../../../core/offline/offline_repository.dart' show LocalIdGenerator;

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

  /// Récupère la session active.
  Future<GazSession?> getActiveSession() {
    return sessionRepository.getActiveSession(enterpriseId);
  }

  /// Ouvre une nouvelle session.
  Future<void> openSession({
    required String userId,
    Map<int, int> openingFullStock = const {},
    Map<int, int> openingEmptyStock = const {},
    double openingCash = 0.0,
    double openingMobileMoney = 0.0,
  }) async {
    final active = await getActiveSession();
    if (active != null) return; // Déjà une session ouverte

    final session = GazSession(
      id: LocalIdGenerator.generate(),
      enterpriseId: enterpriseId,
      status: GazSessionStatus.open,
      openedAt: DateTime.now(),
      openedBy: userId,
      date: DateTime.now(),
      openingFullStock: openingFullStock,
      openingEmptyStock: openingEmptyStock,
      openingCash: openingCash,
      openingMobileMoney: openingMobileMoney,
    );

    await sessionRepository.saveSession(session);
  }

  /// Enregistre une clôture de session.
  Future<void> confirmSessionClosure(GazSession session) async {
    await sessionRepository.saveSession(session.copyWith(
      status: GazSessionStatus.closed,
      closedAt: DateTime.now(),
    ));
  }

  /// Supprime une session.
  Future<void> deleteSession(String id) async {
    await sessionRepository.deleteSession(id);
  }
}
