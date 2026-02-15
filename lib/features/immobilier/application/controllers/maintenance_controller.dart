import '../../../audit_trail/domain/services/audit_trail_service.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../domain/entities/maintenance_ticket.dart';
import '../../domain/repositories/maintenance_repository.dart';
import '../../domain/entities/expense.dart';
import '../controllers/expense_controller.dart';
import '../../../../shared/domain/entities/payment_method.dart';

class MaintenanceController {
  MaintenanceController(
    this._maintenanceRepository,
    this._expenseController,
    this._auditTrailService,
    this._enterpriseId,
    this._userId,
  );

  final MaintenanceRepository _maintenanceRepository;
  final PropertyExpenseController _expenseController;
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
    final oldTicket = await _maintenanceRepository.getTicketById(ticket.id);
    final updated = await _maintenanceRepository.updateTicket(ticket);
    
    // Auto-create expense if status changed to resolved/closed and has cost
    if (updated.cost != null && updated.cost! > 0) {
      if ((updated.status == MaintenanceStatus.resolved || updated.status == MaintenanceStatus.closed) &&
          (oldTicket == null || (oldTicket.status != MaintenanceStatus.resolved && oldTicket.status != MaintenanceStatus.closed))) {
        
        await _expenseController.createExpense(PropertyExpense(
          id: 'maint_${updated.id}', 
          enterpriseId: _enterpriseId,
          propertyId: updated.propertyId,
          category: ExpenseCategory.maintenance,
          amount: updated.cost!.round(),
          description: 'Maintenance: ${updated.description}',
          expenseDate: DateTime.now(),
          paymentMethod: PaymentMethod.cash, 
          createdAt: DateTime.now(),
        ));
      }
    }

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
