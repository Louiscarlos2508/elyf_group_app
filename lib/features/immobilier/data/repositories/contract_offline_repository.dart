import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
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
  String get collectionName => 'contracts';

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
  Future<void> saveToLocal(Contract entity) async {
    final localId = getLocalId(entity);
    final map = toMap(entity)..['localId'] = localId;
    await driftService.records.upsert(
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
  Future<void> deleteFromLocal(Contract entity) async {
    final remoteId = getRemoteId(entity);
    if (remoteId != null) {
      await driftService.records.deleteByRemoteId(
        collectionName: collectionName,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
        moduleType: moduleType,
      );
      return;
    }
    final localId = getLocalId(entity);
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
  }

  @override
  Future<Contract?> getByLocalId(String localId) async {
    final record = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    ) ?? await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );

    if (record == null) return null;
    final map = safeDecodeJson(record.dataJson, record.localId);
    return map != null ? fromMap(map) : null;
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
    final entities = rows
        .map((r) => safeDecodeJson(r.dataJson, r.localId))
        .where((m) => m != null)
        .map((m) => fromMap(m!))
        .toList();
    
    return deduplicateByRemoteId(entities);
  }

  // ContractRepository interface implementation

  @override
  Stream<List<Contract>> watchContracts() {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) {
          final entities = rows
              .map((r) => safeDecodeJson(r.dataJson, r.localId))
              .where((m) => m != null)
              .map((m) => fromMap(m!))
              .where((e) => !e.isDeleted)
              .toList();
          return deduplicateByRemoteId(entities);
        });
  }

  @override
  Stream<List<Contract>> watchDeletedContracts() {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) {
          final entities = rows
              .map((r) => safeDecodeJson(r.dataJson, r.localId))
              .where((m) => m != null)
              .map((m) => fromMap(m!))
              .where((e) => e.isDeleted)
              .toList();
          return deduplicateByRemoteId(entities);
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
        await save(contract.copyWith(
          deletedAt: DateTime.now(),
          deletedBy: 'system',
        ));
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
