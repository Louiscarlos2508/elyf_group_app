import 'dart:developer' as developer;

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/isar_service.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../../../core/offline/collections/machine_collection.dart';
import '../../domain/entities/machine.dart';
import '../../domain/repositories/machine_repository.dart';

/// Offline-first repository for Machine entities.
class MachineOfflineRepository extends OfflineRepository<Machine>
    implements MachineRepository {
  MachineOfflineRepository({
    required super.isarService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
  });

  final String enterpriseId;

  @override
  String get collectionName => 'machines';

  @override
  Machine fromMap(Map<String, dynamic> map) {
    return Machine(
      id: map['id'] as String? ?? map['localId'] as String,
      nom: map['nom'] as String,
      reference: map['reference'] as String,
      description: map['description'] as String?,
      estActive: map['estActive'] as bool? ?? true,
      puissanceKw: (map['puissanceKw'] as num?)?.toDouble(),
      dateInstallation: map['dateInstallation'] != null
          ? DateTime.parse(map['dateInstallation'] as String)
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  @override
  Map<String, dynamic> toMap(Machine entity) {
    return {
      'id': entity.id,
      'nom': entity.nom,
      'reference': entity.reference,
      'description': entity.description,
      'estActive': entity.estActive,
      'puissanceKw': entity.puissanceKw,
      'dateInstallation': entity.dateInstallation?.toIso8601String(),
      'createdAt': entity.createdAt?.toIso8601String(),
      'updatedAt': entity.updatedAt?.toIso8601String(),
    };
  }

  @override
  String getLocalId(Machine entity) {
    if (entity.id.startsWith('local_')) {
      return entity.id;
    }
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(Machine entity) {
    if (!entity.id.startsWith('local_')) {
      return entity.id;
    }
    return null;
  }

  @override
  String? getEnterpriseId(Machine entity) => enterpriseId;

  @override
  Future<void> saveToLocal(Machine entity) async {
    final collection = MachineCollection.fromMap(
      toMap(entity),
      enterpriseId: enterpriseId,
      localId: getLocalId(entity),
    );
    collection.remoteId = getRemoteId(entity) ?? getLocalId(entity);
    collection.localUpdatedAt = DateTime.now();

    await isarService.isar.writeTxn(() async {
      await isarService.isar.machineCollections.put(collection);
    });
  }

  @override
  Future<void> deleteFromLocal(Machine entity) async {
    final remoteId = getRemoteId(entity);
    await isarService.isar.writeTxn(() async {
      if (remoteId != null) {
        await isarService.isar.machineCollections
            .filter()
            .remoteIdEqualTo(remoteId)
            .and()
            .enterpriseIdEqualTo(enterpriseId)
            .deleteAll();
      } else {
        final localId = getLocalId(entity);
        await isarService.isar.machineCollections
            .filter()
            .localIdEqualTo(localId)
            .and()
            .enterpriseIdEqualTo(enterpriseId)
            .deleteAll();
      }
    });
  }

  @override
  Future<Machine?> getByLocalId(String localId) async {
    var collection = await isarService.isar.machineCollections
        .filter()
        .remoteIdEqualTo(localId)
        .and()
        .enterpriseIdEqualTo(enterpriseId)
        .findFirst();

    if (collection != null) {
      return fromMap(collection.toMap());
    }

    collection = await isarService.isar.machineCollections
        .filter()
        .localIdEqualTo(localId)
        .and()
        .enterpriseIdEqualTo(enterpriseId)
        .findFirst();

    if (collection != null) {
      return fromMap(collection.toMap());
    }

    return null;
  }

  @override
  Future<List<Machine>> getAllForEnterprise(String enterpriseId) async {
    final collections = await isarService.isar.machineCollections
        .filter()
        .enterpriseIdEqualTo(enterpriseId)
        .findAll();

    return collections.map((c) => fromMap(c.toMap())).toList();
  }

  // MachineRepository interface implementation

  @override
  Future<List<Machine>> fetchMachines({bool? estActive}) async {
    try {
      developer.log(
        'Fetching machines for enterprise: $enterpriseId',
        name: 'MachineOfflineRepository',
      );
      final allMachines = await getAllForEnterprise(enterpriseId);
      if (estActive != null) {
        return allMachines.where((m) => m.estActive == estActive).toList();
      }
      return allMachines;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching machines',
        name: 'MachineOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<Machine?> fetchMachineById(String id) async {
    try {
      final collection = await isarService.isar.machineCollections
          .filter()
          .remoteIdEqualTo(id)
          .and()
          .enterpriseIdEqualTo(enterpriseId)
          .findFirst();

      if (collection != null) {
        return fromMap(collection.toMap());
      }

      return await getByLocalId(id);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting machine: $id',
        name: 'MachineOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<Machine> createMachine(Machine machine) async {
    try {
      final localId = getLocalId(machine);
      final machineWithLocalId = machine.copyWith(id: localId);
      await save(machineWithLocalId);
      return machineWithLocalId;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error creating machine',
        name: 'MachineOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<Machine> updateMachine(Machine machine) async {
    try {
      await save(machine);
      return machine;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error updating machine: ${machine.id}',
        name: 'MachineOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> deleteMachine(String id) async {
    try {
      final machine = await fetchMachineById(id);
      if (machine != null) {
        await delete(machine);
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error deleting machine: $id',
        name: 'MachineOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }
}

