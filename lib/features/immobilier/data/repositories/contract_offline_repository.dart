import 'package:drift/drift.dart';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/drift/app_database.dart';
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
    final companion = ContractsTableCompanion(
      id: Value(localId),
      enterpriseId: Value(enterpriseId),
      propertyId: Value(entity.propertyId),
      tenantId: Value(entity.tenantId),
      startDate: Value(entity.startDate),
      endDate: Value(entity.endDate),
      monthlyRent: Value(entity.monthlyRent),
      deposit: Value(entity.deposit),
      status: Value(entity.status.name),
      paymentDay: Value(entity.paymentDay),
      notes: Value(entity.notes),
      depositInMonths: Value(entity.depositInMonths),
      entryInventory: Value(entity.entryInventory),
      exitInventory: Value(entity.exitInventory),
      createdAt: Value(entity.createdAt ?? DateTime.now()),
      updatedAt: Value(DateTime.now()),
      deletedAt: Value(entity.deletedAt),
      deletedBy: Value(entity.deletedBy),
    );

    await driftService.db.into(driftService.db.contractsTable).insertOnConflictUpdate(companion);
  }

  @override
  Future<void> deleteFromLocal(Contract entity) async {
    final localId = getLocalId(entity);
    await (driftService.db.delete(driftService.db.contractsTable)
          ..where((t) => t.id.equals(localId)))
        .go();
  }

  @override
  Future<Contract?> getByLocalId(String localId) async {
    final query = driftService.db.select(driftService.db.contractsTable)
      ..where((t) => t.id.equals(localId));
    final row = await query.getSingleOrNull();

    if (row == null) return null;
    return _fromEntity(row);
  }

  Contract _fromEntity(ContractEntity entity) {
    return Contract(
      id: entity.id,
      enterpriseId: entity.enterpriseId,
      propertyId: entity.propertyId,
      tenantId: entity.tenantId,
      startDate: entity.startDate,
      endDate: entity.endDate,
      monthlyRent: entity.monthlyRent,
      deposit: entity.deposit,
      status: ContractStatus.values.firstWhere(
        (e) => e.name == entity.status,
        orElse: () => ContractStatus.pending,
      ),
      paymentDay: entity.paymentDay,
      notes: entity.notes,
      depositInMonths: entity.depositInMonths,
      entryInventory: entity.entryInventory,
      exitInventory: entity.exitInventory,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
      deletedBy: entity.deletedBy,
    );
  }

  @override
  Future<List<Contract>> getAllContracts() async {
    return getAllForEnterprise(enterpriseId);
  }

  @override
  Future<List<Contract>> getAllForEnterprise(String enterpriseId) async {
    final query = driftService.db.select(driftService.db.contractsTable)
      ..where((t) => t.enterpriseId.equals(enterpriseId));
    final rows = await query.get();
    return rows.map(_fromEntity).toList();
  }

  // ContractRepository interface implementation

  @override
  Stream<List<Contract>> watchContracts({bool? isDeleted = false}) {
    var query = driftService.db.select(driftService.db.contractsTable)
      ..where((t) => t.enterpriseId.equals(enterpriseId));

    if (isDeleted != null) {
      if (isDeleted) {
        query.where((t) => t.deletedAt.isNotNull());
      } else {
        query.where((t) => t.deletedAt.isNull());
      }
    }

    return query.watch().map((rows) => rows.map(_fromEntity).toList());
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
