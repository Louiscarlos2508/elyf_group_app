import 'package:drift/drift.dart';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/drift/app_database.dart';
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
  Future<void> saveToLocal(MaintenanceTicket entity, {String? userId}) async {
    final localId = getLocalId(entity);
    final companion = MaintenanceTicketsTableCompanion(
      id: Value(localId),
      enterpriseId: Value(enterpriseId),
      propertyId: Value(entity.propertyId),
      tenantId: Value(entity.tenantId),
      description: Value(entity.description),
      priority: Value(entity.priority.name),
      status: Value(entity.status.name),
      photos: Value(entity.photos?.join(',')),
      cost: Value(entity.cost),
      assignedUserId: Value(entity.assignedUserId),
      createdAt: Value(entity.createdAt ?? DateTime.now()),
      updatedAt: Value(DateTime.now()),
      deletedAt: Value(entity.deletedAt),
      deletedBy: Value(entity.deletedBy),
    );

    await driftService.db.into(driftService.db.maintenanceTicketsTable).insertOnConflictUpdate(companion);
  }

  @override
  Future<void> deleteFromLocal(MaintenanceTicket entity, {String? userId}) async {
    final localId = getLocalId(entity);
    await (driftService.db.delete(driftService.db.maintenanceTicketsTable)
          ..where((t) => t.id.equals(localId)))
        .go();
  }

  @override
  Future<MaintenanceTicket?> getByLocalId(String localId) async {
    final query = driftService.db.select(driftService.db.maintenanceTicketsTable)
      ..where((t) => t.id.equals(localId));
    final row = await query.getSingleOrNull();

    if (row == null) return null;
    return _fromEntity(row);
  }

  MaintenanceTicket _fromEntity(MaintenanceTicketsTableData entity) {
    return MaintenanceTicket(
      id: entity.id,
      enterpriseId: entity.enterpriseId,
      propertyId: entity.propertyId,
      tenantId: entity.tenantId,
      description: entity.description,
      priority: MaintenancePriority.values.firstWhere(
        (e) => e.name == entity.priority,
        orElse: () => MaintenancePriority.medium,
      ),
      status: MaintenanceStatus.values.firstWhere(
        (e) => e.name == entity.status,
        orElse: () => MaintenanceStatus.open,
      ),
      photos: entity.photos?.split(','),
      cost: entity.cost,
      assignedUserId: entity.assignedUserId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
      deletedBy: entity.deletedBy,
    );
  }

  @override
  Future<List<MaintenanceTicket>> getAllForEnterprise(String enterpriseId) async {
    final query = driftService.db.select(driftService.db.maintenanceTicketsTable)
      ..where((t) => t.enterpriseId.equals(enterpriseId));
    final rows = await query.get();
    return rows.map<MaintenanceTicket>(_fromEntity).toList();
  }

  @override
  Stream<List<MaintenanceTicket>> watchAllTickets({bool? isDeleted = false}) {
    var query = driftService.db.select(driftService.db.maintenanceTicketsTable)
      ..where((t) => t.enterpriseId.equals(enterpriseId));

    if (isDeleted != null) {
      if (isDeleted) {
        query.where((t) => t.deletedAt.isNotNull());
      } else {
        query.where((t) => t.deletedAt.isNull());
      }
    }
    
    return query.watch().map((rows) => rows.map<MaintenanceTicket>(_fromEntity).toList());
  }

  @override
  Stream<List<MaintenanceTicket>> watchTicketsByProperty(String propertyId, {bool? isDeleted = false}) {
    var query = driftService.db.select(driftService.db.maintenanceTicketsTable)
      ..where((t) => t.enterpriseId.equals(enterpriseId))
      ..where((t) => t.propertyId.equals(propertyId));

    if (isDeleted != null) {
      if (isDeleted) {
        query.where((t) => t.deletedAt.isNotNull());
      } else {
        query.where((t) => t.deletedAt.isNull());
      }
    }
    
    return query.watch().map((rows) => rows.map<MaintenanceTicket>(_fromEntity).toList());
  }

  @override
  Future<List<MaintenanceTicket>> getTicketsByProperty(String propertyId) async {
    final query = driftService.db.select(driftService.db.maintenanceTicketsTable)
      ..where((t) => t.enterpriseId.equals(enterpriseId))
      ..where((t) => t.propertyId.equals(propertyId))
      ..where((t) => t.deletedAt.isNull());
    final rows = await query.get();
    return rows.map<MaintenanceTicket>(_fromEntity).toList();
  }

  @override
  Future<MaintenanceTicket?> getTicketById(String id) async {
    return await getByLocalId(id);
  }

  @override
  Future<List<MaintenanceTicket>> getTicketsByStatus(MaintenanceStatus status) async {
    final query = driftService.db.select(driftService.db.maintenanceTicketsTable)
      ..where((t) => t.enterpriseId.equals(enterpriseId))
      ..where((t) => t.status.equals(status.name))
      ..where((t) => t.deletedAt.isNull());
    final rows = await query.get();
    return rows.map<MaintenanceTicket>(_fromEntity).toList();
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
        await save(ticket.copyWith(
          deletedAt: DateTime.now(),
          updatedAt: DateTime.now(),
          deletedBy: 'system',
        ));
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
        final restoredTicket = MaintenanceTicket(
          id: ticket.id,
          enterpriseId: ticket.enterpriseId,
          propertyId: ticket.propertyId,
          tenantId: ticket.tenantId,
          description: ticket.description,
          priority: ticket.priority,
          status: ticket.status,
          photos: ticket.photos,
          cost: ticket.cost,
          createdAt: ticket.createdAt,
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
