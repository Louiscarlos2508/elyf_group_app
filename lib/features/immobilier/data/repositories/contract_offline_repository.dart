import 'dart:developer' as developer;
import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../domain/entities/contract.dart';
import '../../domain/repositories/contract_repository.dart';

/// Offline-first repository for Contract entities.
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

  @override
  Contract fromMap(Map<String, dynamic> map) {
    return Contract(
      id: map['id'] as String? ?? map['localId'] as String,
      propertyId: map['propertyId'] as String,
      tenantId: map['tenantId'] as String,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      monthlyRent: (map['monthlyRent'] as num?)?.toInt() ?? 0,
      deposit: (map['deposit'] as num?)?.toInt() ?? 0,
      status: _parseContractStatus(map['status'] as String),
      property: null, // Will be loaded separately if needed
      tenant: null, // Will be loaded separately if needed
      paymentDay: map['paymentDay'] as int?,
      notes: map['notes'] as String?,
      depositInMonths: map['depositInMonths'] as int?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      attachedFiles: null, // Will be loaded separately if needed
    );
  }

  @override
  Map<String, dynamic> toMap(Contract entity) {
    return {
      'id': entity.id,
      'propertyId': entity.propertyId,
      'tenantId': entity.tenantId,
      'startDate': entity.startDate.toIso8601String(),
      'endDate': entity.endDate.toIso8601String(),
      'monthlyRent': entity.monthlyRent.toDouble(),
      'deposit': entity.deposit.toDouble(),
      'status': entity.status.name,
      'paymentDay': entity.paymentDay,
      'notes': entity.notes,
      'depositInMonths': entity.depositInMonths,
      'createdAt': entity.createdAt?.toIso8601String(),
      'updatedAt': entity.updatedAt?.toIso8601String(),
    };
  }

  @override
  String getLocalId(Contract entity) {
    if (entity.id.startsWith('local_')) {
      return entity.id;
    }
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(Contract entity) {
    if (!entity.id.startsWith('local_')) {
      return entity.id;
    }
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
      moduleType: 'immobilier',
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
        moduleType: 'immobilier',
      );
      return;
    }
    final localId = getLocalId(entity);
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'immobilier',
    );
  }

  @override
  Future<Contract?> getByLocalId(String localId) async {
    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'immobilier',
    );
    if (byRemote != null) {
      return fromMap(jsonDecode(byRemote.dataJson) as Map<String, dynamic>);
    }

    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'immobilier',
    );
    if (byLocal == null) return null;
    return fromMap(jsonDecode(byLocal.dataJson) as Map<String, dynamic>);
  }

  @override
  Future<List<Contract>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: 'immobilier',
    );
    return rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .toList();
  }

  // ContractRepository interface implementation

  @override
  Future<List<Contract>> getAllContracts() async {
    try {
      developer.log(
        'Fetching contracts for enterprise: $enterpriseId',
        name: 'ContractOfflineRepository',
      );
      return await getAllForEnterprise(enterpriseId);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching contracts',
        name: 'ContractOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<Contract?> getContractById(String id) async {
    try {
      return await getByLocalId(id);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting contract: $id',
        name: 'ContractOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<List<Contract>> getActiveContracts() async {
    try {
      final allContracts = await getAllForEnterprise(enterpriseId);
      return allContracts.where((c) => c.isActive).toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting active contracts',
        name: 'ContractOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<List<Contract>> getContractsByProperty(String propertyId) async {
    try {
      final allContracts = await getAllForEnterprise(enterpriseId);
      return allContracts
          .where((c) => c.propertyId == propertyId)
          .toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting contracts by property: $propertyId',
        name: 'ContractOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<List<Contract>> getContractsByTenant(String tenantId) async {
    try {
      final allContracts = await getAllForEnterprise(enterpriseId);
      return allContracts
          .where((c) => c.tenantId == tenantId)
          .toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting contracts by tenant: $tenantId',
        name: 'ContractOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<Contract> createContract(Contract contract) async {
    try {
      final localId = getLocalId(contract);
      final contractWithLocalId = Contract(
        id: localId,
        propertyId: contract.propertyId,
        tenantId: contract.tenantId,
        startDate: contract.startDate,
        endDate: contract.endDate,
        monthlyRent: contract.monthlyRent,
        deposit: contract.deposit,
        status: contract.status,
        property: contract.property,
        tenant: contract.tenant,
        paymentDay: contract.paymentDay,
        notes: contract.notes,
        depositInMonths: contract.depositInMonths,
        createdAt: contract.createdAt,
        updatedAt: contract.updatedAt,
        attachedFiles: contract.attachedFiles,
      );
      await save(contractWithLocalId);
      return contractWithLocalId;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error creating contract',
        name: 'ContractOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<Contract> updateContract(Contract contract) async {
    try {
      await save(contract);
      return contract;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error updating contract: ${contract.id}',
        name: 'ContractOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
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
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error deleting contract: $id',
        name: 'ContractOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  ContractStatus _parseContractStatus(String status) {
    switch (status) {
      case 'active':
        return ContractStatus.active;
      case 'expired':
        return ContractStatus.expired;
      case 'terminated':
        return ContractStatus.terminated;
      case 'pending':
        return ContractStatus.pending;
      default:
        return ContractStatus.pending;
    }
  }
}

