import '../entities/gaz_session.dart';

/// Interface pour le repository des clôtures de session gaz.
abstract class GazSessionRepository {
  Future<List<GazSession>> getSessions({DateTime? from, DateTime? to});
  Stream<List<GazSession>> watchSessions({DateTime? from, DateTime? to});
  Future<GazSession?> getSessionById(String id);
  Future<void> saveSession(GazSession session);
  Future<void> deleteSession(String id);
  Future<GazSession?> getSessionByDate(DateTime date);
}
