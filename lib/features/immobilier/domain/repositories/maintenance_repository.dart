import '../entities/maintenance_ticket.dart';

abstract class MaintenanceRepository {
  Future<List<MaintenanceTicket>> getTicketsByProperty(String propertyId);
  Future<List<MaintenanceTicket>> getTicketsByStatus(MaintenanceStatus status);
  Future<MaintenanceTicket> createTicket(MaintenanceTicket ticket);
  Future<MaintenanceTicket> updateTicket(MaintenanceTicket ticket);
  Future<void> deleteTicket(String id);
  Future<void> restoreTicket(String id);
  
  Stream<List<MaintenanceTicket>> watchTicketsByProperty(String propertyId, {bool? isDeleted = false});
  Stream<List<MaintenanceTicket>> watchAllTickets({bool? isDeleted = false});
}
