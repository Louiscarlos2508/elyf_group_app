import '../entities/closing.dart';

abstract class ClosingRepository {
  Future<Closing?> getCurrentSession();
  Future<String> openSession(Closing session);
  Future<void> closeSession(Closing session);
  Future<List<Closing>> fetchHistory({int limit = 50});
  Stream<Closing?> watchCurrentSession();
}
