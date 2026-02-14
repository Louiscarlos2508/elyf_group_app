import '../entities/treasury_operation.dart';

abstract class TreasuryRepository {
  /// Save an operation.
  Future<String> createOperation(TreasuryOperation operation);
  
  /// Get an operation by ID.
  Future<TreasuryOperation?> getOperation(String id);
  
  /// Get all operations for the enterprise.
  Future<List<TreasuryOperation>> fetchOperations({int limit = 50});
  
  /// Watch operations for reactive UI.
  Stream<List<TreasuryOperation>> watchOperations({int limit = 50});
  
  /// Get current balances (cash & mobileMoney) by replaying operations.
  Future<Map<String, int>> getBalances();
}
