
import '../entities/closing.dart';

/// Repository for managing financial closing records.
abstract class ClosingRepository {
  Future<List<Closing>> fetchClosings({int limit = 50});
  Future<Closing?> getClosing(String id);
  Future<Closing?> getActiveSession();
  Future<String> createClosing(Closing closing);
  Future<void> updateClosing(Closing closing);
  Future<List<Closing>> getClosingsInPeriod(DateTime start, DateTime end);
  Future<int> getCountForDate(DateTime date);
  Stream<List<Closing>> watchClosings({int limit = 50});
  Stream<Closing?> watchActiveSession();
}
