import '../../domain/entities/production_session.dart';
import '../../domain/repositories/production_session_repository.dart';

class ProductionSessionController {
  ProductionSessionController(this._repository);

  final ProductionSessionRepository _repository;

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

  Future<ProductionSession> createSession(ProductionSession session) async {
    return _repository.createSession(session);
  }

  Future<ProductionSession> updateSession(ProductionSession session) async {
    return _repository.updateSession(session);
  }

  Future<void> deleteSession(String id) async {
    return _repository.deleteSession(id);
  }
}

