import '../../../audit_trail/domain/services/audit_trail_service.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../domain/entities/maintenance_ticket.dart';
import '../../domain/repositories/maintenance_repository.dart';

class MaintenanceController {
  MaintenanceController(
    this._maintenanceRepository,
    this._auditTrailService,
    this._enterpriseId,
    this._userId,
  );

  final MaintenanceRepository _maintenanceRepository;
  final AuditTrailService _auditTrailService;
  final String _enterpriseId;
  final String _userId;

  Stream<List<MaintenanceTicket>> watchTicketsByProperty(String propertyId, {bool? isDeleted = false}) {
    return _maintenanceRepository.watchTicketsByProperty(propertyId, isDeleted: isDeleted);
  }

  Stream<List<MaintenanceTicket>> watchAllTickets({bool? isDeleted = false}) {
    return _maintenanceRepository.watchAllTickets(isDeleted: isDeleted);
  }

  Future<List<MaintenanceTicket>> getTicketsByProperty(String propertyId) async {
    return await _maintenanceRepository.getTicketsByProperty(propertyId);
  }

  Future<List<MaintenanceTicket>> getTicketsByStatus(MaintenanceStatus status) async {
    return await _maintenanceRepository.getTicketsByStatus(status);
  }

  Future<MaintenanceTicket> createTicket(MaintenanceTicket ticket) async {
    final created = await _maintenanceRepository.createTicket(ticket);
    await _logAction('create', created.id, metadata: created.toMap());
    return created;
  }

  Future<MaintenanceTicket> updateTicket(MaintenanceTicket ticket) async {
    final updated = await _maintenanceRepository.updateTicket(ticket);
    await _logAction('update', updated.id, metadata: updated.toMap());
    return updated;
  }

  Future<void> deleteTicket(String id) async {
    await _maintenanceRepository.deleteTicket(id);
    await _logAction('delete', id);
  }

  Future<void> restoreTicket(String id) async {
    await _maintenanceRepository.restoreTicket(id);
    await _logAction('restore', id);
  }

  Future<void> _logAction(
    String action,
    String entityId, {
    Map<String, dynamic>? metadata,
  }) async {
    await _auditTrailService.logAction(
      enterpriseId: _enterpriseId,
      userId: _userId,
      module: 'immobilier',
      action: action,
      entityId: entityId,
      entityType: 'maintenance_ticket',
      metadata: metadata,
    );
  }
}
