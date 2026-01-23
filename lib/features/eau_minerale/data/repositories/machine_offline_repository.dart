import 'dart:developer' as developer;
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
    final localId = getLocalId(entity);
    final map = toMap(entity)..['localId'] = localId;
    await driftService.records.upsert(
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
  Future<void> deleteFromLocal(Machine entity) async {
    final remoteId = getRemoteId(entity);
    if (remoteId != null) {
      await driftService.records.deleteByRemoteId(
        collectionName: collectionName,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
        moduleType: 'eau_minerale',
      );
      return;
    }
    final localId = getLocalId(entity);
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
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
      return fromMap(jsonDecode(byRemote.dataJson) as Map<String, dynamic>);
    }

    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
    );
    if (byLocal == null) return null;
    return fromMap(jsonDecode(byLocal.dataJson) as Map<String, dynamic>);
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
        developer.log(
          'Machine with reference ${machine.reference} already exists: ${existingMachine.id}',
          name: 'MachineOfflineRepository',
        );
        throw ValidationException(
          'Une machine avec la référence "${machine.reference}" existe déjà',
          'MACHINE_REFERENCE_DUPLICATE',
        );
      }
      
      final localId = getLocalId(machine);
      final machineWithLocalId = machine.copyWith(id: localId);
      await save(machineWithLocalId);
      return machineWithLocalId;
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
      await save(machine);
      return machine;
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
