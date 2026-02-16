import 'package:elyf_groupe_app/shared/domain/entities/treasury_operation.dart';

abstract class GazTreasuryRepository {
  Future<List<TreasuryOperation>> getOperations(String enterpriseId, {DateTime? from, DateTime? to, List<String>? enterpriseIds});
  Stream<List<TreasuryOperation>> watchOperations(String enterpriseId, {DateTime? from, DateTime? to, List<String>? enterpriseIds});
  Future<void> saveOperation(TreasuryOperation operation);
  Future<void> deleteOperation(String id);
  Future<Map<String, int>> getBalances(String enterpriseId, {List<String>? enterpriseIds});
}
