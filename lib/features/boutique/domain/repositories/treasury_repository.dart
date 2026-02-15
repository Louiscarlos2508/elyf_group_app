import '../entities/treasury_operation.dart';

abstract class TreasuryRepository {
  Future<List<TreasuryOperation>> fetchOperations({int limit = 50});
  Future<TreasuryOperation?> getOperation(String id);
  Future<String> createOperation(TreasuryOperation operation);
  Stream<List<TreasuryOperation>> watchOperations({int limit = 50});
  Future<Map<String, int>> getBalances();
  Stream<Map<String, int>> watchBalances();
}
