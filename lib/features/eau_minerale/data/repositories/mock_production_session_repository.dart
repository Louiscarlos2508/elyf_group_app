import '../../domain/entities/production_session.dart';
import '../../domain/repositories/production_session_repository.dart';

class MockProductionSessionRepository implements ProductionSessionRepository {
  final List<ProductionSession> _sessions = [];

  @override
  Future<List<ProductionSession>> fetchSessions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    var sessions = List<ProductionSession>.from(_sessions);

    if (startDate != null) {
      sessions = sessions.where((s) => s.date.isAfter(startDate) || 
          s.date.isAtSameMomentAs(startDate)).toList();
    }

    if (endDate != null) {
      sessions = sessions.where((s) => s.date.isBefore(endDate) || 
          s.date.isAtSameMomentAs(endDate)).toList();
    }

    return sessions..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<ProductionSession?> fetchSessionById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _sessions.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<ProductionSession> createSession(ProductionSession session) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final newSession = session.copyWith(
      id: 'session-${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _sessions.add(newSession);
    return newSession;
  }

  @override
  Future<ProductionSession> updateSession(ProductionSession session) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _sessions.indexWhere((s) => s.id == session.id);
    if (index == -1) {
      throw Exception('Session non trouvée');
    }
    final updatedSession = session.copyWith(updatedAt: DateTime.now());
    _sessions[index] = updatedSession;
    return updatedSession;
  }

  @override
  Future<void> deleteSession(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _sessions.removeWhere((s) => s.id == id);
  }
}

