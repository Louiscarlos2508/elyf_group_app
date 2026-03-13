import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/collection_names.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../domain/entities/contract.dart';
import '../../domain/repositories/contract_repository.dart';

/// Offline-first repository for Contract entities (immobilier module).
class ContractOfflineRepository extends OfflineRepository<Contract>
    implements ContractRepository {
  ContractOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
  });

  final String enterpriseId;

  @override
  String get collectionName => CollectionNames.contracts;

  String get moduleType => 'immobilier';

  @override
  Contract fromMap(Map<String, dynamic> map) => Contract.fromMap(map);

  @override
  Map<String, dynamic> toMap(Contract entity) => entity.toMap();

  @override
  String getLocalId(Contract entity) {
    if (entity.id.isNotEmpty) return entity.id;
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(Contract entity) {
    if (!LocalIdGenerator.isLocalId(entity.id)) return entity.id;
    return null;
  }

  @override
  String? getEnterpriseId(Contract entity) => enterpriseId;

  @override
  Future<void> saveToLocal(Contract entity, {String? userId}) async {
    final localId = getLocalId(entity);
    final map = toMap(entity);
    map['localId'] = localId;

    await driftService.records.upsert(
      userId: syncManager.getUserId() ?? '',
      collectionName: collectionName,
      localId: localId,
      remoteId: getRemoteId(entity),
      enterpriseId: enterpriseId,
      moduleType: moduleType,
      dataJson: jsonEncode(map),
      localUpdatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteFromLocal(Contract entity, {String? userId}) async {
    final localId = getLocalId(entity);
    // Soft-delete
    final deletedContract = entity.copyWith(
      deletedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      deletedBy: 'system',
    );
    await saveToLocal(deletedContract, userId: userId);
  }

  @override
  Future<Contract?> getByLocalId(String localId) async {
    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byRemote != null) {
      final contract = fromMap(jsonDecode(byRemote.dataJson) as Map<String, dynamic>);
      return contract.isDeleted ? null : contract;
    }

    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byLocal == null) return null;
    return fromMap(jsonDecode(byLocal.dataJson) as Map<String, dynamic>);
  }

  @override
  Future<List<Contract>> getAllContracts() async {
    return getAllForEnterprise(enterpriseId);
  }

  @override
  Future<List<Contract>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    return rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .where((c) => !c.isDeleted)
        .toList();
  }

  // ContractRepository interface implementation

  @override
  Stream<List<Contract>> watchContracts({bool? isDeleted = false}) {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) {
      return rows
          .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
          .where((c) {
        if (isDeleted == null) return true;
        return c.isDeleted == isDeleted;
      }).toList();
    });
  }

  @override
  Future<Contract?> getContractById(String id) async {
    try {
      return await getByLocalId(id);
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }

  @override
  Future<List<Contract>> getActiveContracts() async {
    final all = await getAllContracts();
    return all.where((c) => c.isActive).toList();
  }

  @override
  Future<List<Contract>> getContractsByProperty(String propertyId) async {
    final all = await getAllContracts();
    return all.where((c) => c.propertyId == propertyId).toList();
  }

  @override
  Future<List<Contract>> getContractsByTenant(String tenantId) async {
    final all = await getAllContracts();
    return all.where((c) => c.tenantId == tenantId).toList();
  }

  @override
  Future<Contract> createContract(Contract contract) async {
    try {
      final localId = contract.id.isEmpty ? LocalIdGenerator.generate() : contract.id;
      final newContract = contract.copyWith(
        id: localId,
        enterpriseId: enterpriseId,
        createdAt: contract.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await save(newContract);
      return newContract;
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }

  @override
  Future<Contract> updateContract(Contract contract) async {
    try {
      final updatedContract = contract.copyWith(updatedAt: DateTime.now());
      await save(updatedContract);
      return updatedContract;
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }

  @override
  Future<void> deleteContract(String id) async {
    try {
      final contract = await getContractById(id);
      if (contract != null) {
        await delete(contract);
      }
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }

  @override
  Future<void> restoreContract(String id) async {
    try {
      final contract = await getContractById(id);
      if (contract != null) {
        await save(contract.copyWith(
          deletedAt: null,
          deletedBy: null,
        ));
      }
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }
}
