import 'package:elyf_groupe_app/shared/domain/entities/treasury_operation.dart';

abstract class OrangeMoneyTreasuryRepository {
  Future<List<TreasuryOperation>> getOperations(
    String enterpriseId, {
    DateTime? from,
    DateTime? to,
    List<String>? enterpriseIds,
    String? referenceEntityId,
    String? referenceEntityType,
  });

  Stream<List<TreasuryOperation>> watchOperations(
    String enterpriseId, {
    DateTime? from,
    DateTime? to,
    List<String>? enterpriseIds,
    String? referenceEntityId,
    String? referenceEntityType,
  });
  
  Future<void> saveOperation(TreasuryOperation operation);
  Future<void> deleteOperation(String id);
  Future<void> deleteOperationsByReference(String entityId, String entityType);
  Future<Map<String, int>> getBalances(String enterpriseId, {List<String>? enterpriseIds});
  Stream<Map<String, int>> watchBalances(String enterpriseId, {List<String>? enterpriseIds});
}
