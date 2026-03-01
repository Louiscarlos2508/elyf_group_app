import 'dart:convert';

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../domain/entities/machine.dart';
import '../../domain/repositories/machine_repository.dart';

/// Offline-first repository for Machine entities.
class MachineOfflineRepository extends OfflineRepository<Machine>
    implements MachineRepository {
  MachineOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
  });

  final String enterpriseId;

  @override
  String get collectionName => 'machines';

  @override
  Machine fromMap(Map<String, dynamic> map) =>
      Machine.fromMap(map, enterpriseId);

  @override
  Map<String, dynamic> toMap(Machine entity) => entity.toMap();

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
  Future<void> saveToLocal(Machine entity, {String? userId}) async {
    final localId = getLocalId(entity);
    final map = toMap(entity)..['localId'] = localId;
    await driftService.records.upsert(userId: syncManager.getUserId() ?? '', 
      collectionName: collectionName,
      localId: localId,
      remoteId: getRemoteId(entity),
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
      dataJson: jsonEncode(map),
      localUpdatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteFromLocal(Machine entity, {String? userId}) async {
    // Soft-delete
    final deletedMachine = entity.copyWith(
      deletedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await saveToLocal(deletedMachine, userId: syncManager.getUserId() ?? '');
    
    AppLogger.info(
      'Soft-deleted machine: ${entity.id}',
      name: 'MachineOfflineRepository',
    );
  }

  @override
  Future<Machine?> getByLocalId(String localId) async {
    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
    );
    if (byRemote != null) {
      final machine = fromMap(jsonDecode(byRemote.dataJson) as Map<String, dynamic>);
      return machine.isDeleted ? null : machine;
    }

    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
    );
    if (byLocal == null) return null;
    final machine = fromMap(jsonDecode(byLocal.dataJson) as Map<String, dynamic>);
    return machine.isDeleted ? null : machine;
  }

  @override
  Future<List<Machine>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
    );
    final entities = rows
        .map((r) {
          try {
            return fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>);
          } catch (e, stackTrace) {
            final appException = ErrorHandler.instance.handleError(e, stackTrace);
            AppLogger.warning(
              'Error decoding machine data: ${appException.message}',
              name: 'MachineOfflineRepository',
              error: e,
              stackTrace: stackTrace,
            );
            return null;
          }
        })
        .whereType<Machine>()
        .where((m) => !m.isDeleted)
        .toList();

    // Dédupliquer par remoteId d'abord
    final deduplicatedByRemoteId = deduplicateByRemoteId(entities);
    
    // Ensuite dédupliquer par référence pour éviter les doublons même sans remoteId
    return _deduplicateByReference(deduplicatedByRemoteId);
  }

  /// Déduplique les machines par référence.
  ///
  /// Garde la machine la plus récente pour chaque référence unique.
  List<Machine> _deduplicateByReference(List<Machine> machines) {
    final Map<String, Machine> machinesByReference = {};
    
    for (final machine in machines) {
      final reference = machine.reference.trim().toUpperCase();
      if (!machinesByReference.containsKey(reference)) {
        machinesByReference[reference] = machine;
      } else {
        // Garder la machine la plus récente
        final existing = machinesByReference[reference]!;
        final existingUpdatedAt = existing.updatedAt ?? existing.createdAt ?? DateTime(1970);
        final currentUpdatedAt = machine.updatedAt ?? machine.createdAt ?? DateTime(1970);
        if (currentUpdatedAt.isAfter(existingUpdatedAt)) {
          machinesByReference[reference] = machine;
        }
      }
    }
    
    return machinesByReference.values.toList();
  }

  /// Trouve une machine par sa référence.
  Future<Machine?> findMachineByReference(String reference) async {
    final allMachines = await getAllForEnterprise(enterpriseId);
    final normalizedReference = reference.trim().toUpperCase();
    try {
      return allMachines.firstWhere(
        (m) => m.reference.trim().toUpperCase() == normalizedReference,
      );
    } catch (_) {
      return null;
    }
  }

  // MachineRepository interface implementation

  @override
  Future<List<Machine>> fetchMachines({bool? estActive}) async {
    try {
      AppLogger.debug(
        'Fetching machines for enterprise: $enterpriseId',
        name: 'MachineOfflineRepository',
      );
      final allMachines = await getAllForEnterprise(enterpriseId);
      final activeMachines = allMachines.where((m) => !m.isDeleted);
      if (estActive != null) {
        return activeMachines.where((m) => m.isActive == estActive).toList();
      }
      return activeMachines.toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error fetching machines: ${appException.message}',
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
      return await getByLocalId(id);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting machine: $id - ${appException.message}',
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
      // Vérifier si une machine avec la même référence existe déjà
      final existingMachine = await findMachineByReference(machine.reference);
      if (existingMachine != null) {
        AppLogger.debug(
          'Machine with reference ${machine.reference} already exists: ${existingMachine.id}',
          name: 'MachineOfflineRepository',
        );
        throw ValidationException(
          'Une machine avec la référence "${machine.reference}" existe déjà',
          'MACHINE_REFERENCE_DUPLICATE',
        );
      }
      
      final localId = getLocalId(machine);
      final machineToSave = machine.copyWith(
        id: localId,
        enterpriseId: enterpriseId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await save(machineToSave);
      return machineToSave;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error creating machine: ${appException.message}',
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
      final updated = machine.copyWith(
        enterpriseId: enterpriseId,
        updatedAt: DateTime.now(),
      );
      await save(updated);
      return updated;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error updating machine: ${machine.id} - ${appException.message}',
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
      AppLogger.error(
        'Error deleting machine: $id - ${appException.message}',
        name: 'MachineOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }
}
