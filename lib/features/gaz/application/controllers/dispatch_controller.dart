import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../administration/domain/repositories/admin_repository.dart';
import '../../../administration/application/providers.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import '../../domain/entities/gas_sale.dart';
import '../../domain/repositories/gas_repository.dart';
import '../../domain/services/gaz_dispatch_service.dart';
import '../providers.dart';

class DispatchController {
  DispatchController({
    required this.gasRepository,
    required this.adminRepository,
    required this.dispatchService,
    required this.enterpriseId,
  });

  final GasRepository gasRepository;
  final AdminRepository adminRepository;
  final GazDispatchService dispatchService;
  final String enterpriseId;

  /// Récupère les ventes wholesale en attente de livraison.
  Stream<List<GasSale>> watchPendingWholesaleSales() {
    return gasRepository.watchSales().map((sales) {
      return sales
          .where((s) =>
              s.saleType == SaleType.wholesale &&
              s.deliveryStatus == DeliveryStatus.pending)
          .toList();
    });
  }

  /// Récupère les ventes en cours de livraison.
  Stream<List<GasSale>> watchInProgressDeliveries() {
    return gasRepository.watchSales().map((sales) {
      return sales
          .where((s) => s.deliveryStatus == DeliveryStatus.inProgress)
          .toList();
    });
  }

  /// Récupère les utilisateurs ayant le rôle 'delivery' pour le module gaz.
  Future<List<String>> getAvailableDeliveryPersons() async {
    final users = await adminRepository.getEnterpriseModuleUsersByEnterpriseAndModule(
      enterpriseId,
      'gaz',
    );
    
    // On filtre les utilisateurs qui ont le rôle 'delivery'
    // Note: 'delivery' est l'ID du rôle standard dans ELYF
    return users
        .where((u) => u.isActive && u.roleIds.contains('delivery'))
        .map((u) => u.userId)
        .toList();
  }

  /// Assigne une livraison.
  Future<void> assignDelivery(String saleId, String deliveryPersonId, String assignedBy) async {
    await dispatchService.assignDelivery(
      saleId: saleId,
      deliveryPersonId: deliveryPersonId,
      assignedBy: assignedBy,
    );
  }

  /// Met à jour le statut.
  Future<void> updateStatus(String saleId, DeliveryStatus status, String updatedBy, {String? proofOfDelivery}) async {
    await dispatchService.updateDeliveryStatus(
      saleId: saleId,
      status: status,
      updatedBy: updatedBy,
      proofOfDelivery: proofOfDelivery,
    );
  }
}

/// Provider pour le DispatchController.
final dispatchControllerProvider = Provider<DispatchController>((ref) {
  final gasRepo = ref.watch(gasRepositoryProvider);
  final adminRepo = ref.watch(adminRepositoryProvider);
  final dispatchService = ref.watch(gazDispatchServiceProvider);
  final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? '';

  return DispatchController(
    gasRepository: gasRepo,
    adminRepository: adminRepo,
    dispatchService: dispatchService,
    enterpriseId: enterpriseId,
  );
});
