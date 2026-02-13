import 'dart:convert';

import 'package:drift/drift.dart'; // For Value
import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../domain/entities/maintenance_ticket.dart';
import '../../domain/repositories/maintenance_repository.dart';

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
  String get collectionName => 'maintenance_tickets';

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
  Future<void> saveToLocal(MaintenanceTicket entity) async {
    final localId = getLocalId(entity);
    final map = toMap(entity)..['localId'] = localId; // Ensure localId is in map for robust decoding if needed
    
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
  Future<void> deleteFromLocal(MaintenanceTicket entity) async {
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
  Future<MaintenanceTicket?> getByLocalId(String localId) async {
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
  Future<List<MaintenanceTicket>> getTicketsByProperty(String propertyId) async {
    final all = await getAllForEnterprise(enterpriseId);
    return all.where((t) => t.propertyId == propertyId && !t.isDeleted).toList();
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
        // Soft delete
        await save(ticket.copyWith(
          deletedAt: DateTime.now(),
          deletedBy: 'system',
        ));
      }
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }

  @override
  Future<List<MaintenanceTicket>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    final tickets = rows
        .map((r) => safeDecodeJson(r.dataJson, r.localId))
        .where((m) => m != null)
        .map((m) => fromMap(m!))
        .toList();
    
    return deduplicateByRemoteId(tickets);
  }

  @override
  Stream<List<MaintenanceTicket>> watchTicketsByProperty(String propertyId) {
    return watchAllTickets().map((tickets) => 
      tickets.where((t) => t.propertyId == propertyId).toList()
    );
  }

  @override
  Stream<List<MaintenanceTicket>> watchAllTickets() {
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
}
