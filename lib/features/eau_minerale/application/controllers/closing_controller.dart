import '../../domain/entities/closing.dart';
import '../../domain/repositories/closing_repository.dart';
import '../../../../core/logging/app_logger.dart';

class ClosingController {
  ClosingController(this._closingRepository);

  final ClosingRepository _closingRepository;

  Future<Closing?> getCurrentSession() async {
    return await _closingRepository.getCurrentSession();
  }

  Stream<Closing?> watchCurrentSession() {
    return _closingRepository.watchCurrentSession();
  }

  Future<String> openSession(Closing session) async {
    try {
      return await _closingRepository.openSession(session);
    } catch (e) {
      AppLogger.error('Error opening session', error: e);
      rethrow;
    }
  }

  Future<void> closeSession(Closing session) async {
    try {
      await _closingRepository.closeSession(session);
    } catch (e) {
      AppLogger.error('Error closing session', error: e);
      rethrow;
    }
  }

  Future<List<Closing>> fetchHistory() async {
    return await _closingRepository.fetchHistory();
  }
}
