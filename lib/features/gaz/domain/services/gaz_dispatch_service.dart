import '../../../../core/errors/app_exceptions.dart';
import '../../../audit_trail/domain/entities/audit_record.dart';
import '../../../audit_trail/domain/repositories/audit_trail_repository.dart';
import '../entities/gas_sale.dart';
import '../repositories/gas_repository.dart';

/// Service pour gérer la logistique et l'expédition des ventes en gros.
class GazDispatchService {
  const GazDispatchService({
    required this.gasRepository,
    required this.auditTrailRepository,
  });

  final GasRepository gasRepository;
  final AuditTrailRepository auditTrailRepository;

  /// Assigne une vente wholesale à un livreur.
  Future<void> assignDelivery({
    required String saleId,
    required String deliveryPersonId,
    required String assignedBy,
  }) async {
    final sale = await gasRepository.getSaleById(saleId);
    if (sale == null) throw NotFoundException('Vente introuvable', 'SALE_NOT_FOUND');

    final updatedSale = sale.copyWith(
      deliveryPersonId: deliveryPersonId,
      deliveryStatus: DeliveryStatus.inProgress,
    );

    await gasRepository.updateSale(updatedSale);

    await auditTrailRepository.log(AuditRecord(
      id: '',
      enterpriseId: sale.enterpriseId,
      userId: assignedBy,
      module: 'gaz',
      action: 'DELIVERY_ASSIGNED',
      entityId: sale.id,
      entityType: 'sale',
      timestamp: DateTime.now(),
      metadata: {
        'deliveryPersonId': deliveryPersonId,
        'assignedBy': assignedBy,
      },
    ));
  }

  /// Met à jour le statut de livraison (ex: Livré ou Annulé).
  Future<void> updateDeliveryStatus({
    required String saleId,
    required DeliveryStatus status,
    required String updatedBy,
    String? proofOfDelivery,
  }) async {
    final sale = await gasRepository.getSaleById(saleId);
    if (sale == null) throw NotFoundException('Vente introuvable', 'SALE_NOT_FOUND');

    final updatedSale = sale.copyWith(
      deliveryStatus: status,
      deliveredAt: status == DeliveryStatus.delivered ? DateTime.now() : null,
      proofOfDelivery: proofOfDelivery,
    );

    await gasRepository.updateSale(updatedSale);

    await auditTrailRepository.log(AuditRecord(
      id: '',
      enterpriseId: sale.enterpriseId,
      userId: updatedBy,
      module: 'gaz',
      action: 'DELIVERY_STATUS_UPDATED',
      entityId: sale.id,
      entityType: 'sale',
      timestamp: DateTime.now(),
      metadata: {
        'newStatus': status.name,
        'updatedBy': updatedBy,
      },
    ));
  }

  /// Annule une livraison et remet la vente en attente.
  Future<void> cancelDelivery({
    required String saleId,
    required String cancelledBy,
  }) async {
    final sale = await gasRepository.getSaleById(saleId);
    if (sale == null) throw NotFoundException('Vente introuvable', 'SALE_NOT_FOUND');

    final updatedSale = sale.copyWith(
      deliveryStatus: DeliveryStatus.pending,
      deliveryPersonId: null,
      deliveredAt: null,
    );

    await gasRepository.updateSale(updatedSale);

    await auditTrailRepository.log(AuditRecord(
      id: '',
      enterpriseId: sale.enterpriseId,
      userId: cancelledBy,
      module: 'gaz',
      action: 'DELIVERY_CANCELLED',
      entityId: sale.id,
      entityType: 'sale',
      timestamp: DateTime.now(),
      metadata: {
        'cancelledBy': cancelledBy,
      },
    ));
  }
}
