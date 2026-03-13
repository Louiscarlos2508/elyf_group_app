import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/collection_names.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../domain/entities/maintenance_ticket.dart';
import '../../domain/repositories/maintenance_repository.dart';

/// Offline-first repository for MaintenanceTicket entities (immobilier module).
class MaintenanceOfflineRepository extends OfflineRepository<MaintenanceTicket>
    implements MaintenanceRepository {
  MaintenanceOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
  });

  final String enterpriseId;

  @override
  String get collectionName => CollectionNames.maintenanceTickets;

  String get moduleType => 'immobilier';

  @override
  MaintenanceTicket fromMap(Map<String, dynamic> map) =>
      MaintenanceTicket.fromMap(map);

  @override
  Map<String, dynamic> toMap(MaintenanceTicket entity) => entity.toMap();

  @override
  String getLocalId(MaintenanceTicket entity) {
    if (entity.id.isNotEmpty) return entity.id;
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(MaintenanceTicket entity) {
    if (!LocalIdGenerator.isLocalId(entity.id)) return entity.id;
    return null;
  }

  @override
  String? getEnterpriseId(MaintenanceTicket entity) => enterpriseId;

  @override
  Future<void> saveToLocal(MaintenanceTicket entity, {String? userId}) async {
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
  Future<void> deleteFromLocal(MaintenanceTicket entity, {String? userId}) async {
    final localId = getLocalId(entity);
    // Soft-delete
    final deletedTicket = entity.copyWith(
      deletedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      deletedBy: 'system',
    );
    await saveToLocal(deletedTicket, userId: userId);
  }

  @override
  Future<MaintenanceTicket?> getByLocalId(String localId) async {
    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byRemote != null) {
      final ticket = fromMap(jsonDecode(byRemote.dataJson) as Map<String, dynamic>);
      return ticket.isDeleted ? null : ticket;
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
  Future<List<MaintenanceTicket>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    return rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .toList();
  }

  @override
  Stream<List<MaintenanceTicket>> watchAllTickets({bool? isDeleted = false}) {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) {
      return rows
          .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
          .where((t) {
        if (isDeleted == null) return true;
        return t.isDeleted == isDeleted;
      }).toList();
    });
  }

  @override
  Stream<List<MaintenanceTicket>> watchTicketsByProperty(String propertyId, {bool? isDeleted = false}) {
    return watchAllTickets(isDeleted: isDeleted).map((tickets) {
      return tickets.where((t) => t.propertyId == propertyId).toList();
    });
  }

  @override
  Future<List<MaintenanceTicket>> getTicketsByProperty(String propertyId) async {
    final all = await getAllForEnterprise(enterpriseId);
    return all.where((t) => t.propertyId == propertyId && !t.isDeleted).toList();
  }

  @override
  Future<MaintenanceTicket?> getTicketById(String id) async {
    return getByLocalId(id);
  }

  @override
  Future<List<MaintenanceTicket>> getTicketsByStatus(MaintenanceStatus status) async {
    final all = await getAllForEnterprise(enterpriseId);
    return all.where((t) => t.status == status && !t.isDeleted).toList();
  }

  @override
  Future<MaintenanceTicket> createTicket(MaintenanceTicket ticket) async {
    try {
      final localId = ticket.id.isEmpty ? LocalIdGenerator.generate() : ticket.id;
      final newTicket = ticket.copyWith(
        id: localId,
        enterpriseId: enterpriseId,
        createdAt: ticket.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await save(newTicket);
      return newTicket;
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }

  @override
  Future<MaintenanceTicket> updateTicket(MaintenanceTicket ticket) async {
    try {
      final updatedTicket = ticket.copyWith(updatedAt: DateTime.now());
      await save(updatedTicket);
      return updatedTicket;
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }

  @override
  Future<void> deleteTicket(String id) async {
    try {
      final ticket = await getByLocalId(id);
      if (ticket != null) {
        await delete(ticket);
      }
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }

  @override
  Future<void> restoreTicket(String id) async {
    try {
      final ticket = await getByLocalId(id);
      if (ticket != null) {
        final restoredTicket = ticket.copyWith(
          updatedAt: DateTime.now(),
          deletedAt: null,
          deletedBy: null,
        );
        await save(restoredTicket);
      }
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }
}
