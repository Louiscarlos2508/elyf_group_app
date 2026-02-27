import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import '../../../../../../core/errors/error_handler.dart';
import '../../../../../../core/logging/app_logger.dart';
import '../../../domain/entities/cylinder.dart';
import '../../../domain/entities/gas_sale.dart';
import '../../../../audit_trail/application/providers.dart';
import '../../../../../../core/auth/providers.dart';

/// Handler pour la soumission du formulaire de vente de gaz.
class GasSaleSubmitHandler {
  GasSaleSubmitHandler._();

  static Future<GasSale?> submit({
    required BuildContext context,
    required WidgetRef ref,
    required Cylinder selectedCylinder,
    required int quantity,
    required int availableStock,
    required String enterpriseId,
    required SaleType saleType,
    required String? customerName,
    required String? customerPhone,
    required String? notes,
    required double totalAmount,
    required double unitPrice,
    String? tourId,
    String? wholesalerId,
    String? wholesalerName,
    int emptyReturnedQuantity = 0,
    GasSaleDealType dealType = GasSaleDealType.exchange,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    double? cashAmount,
    double? mobileMoneyAmount,
    required VoidCallback onLoadingChanged,
  }) async {
    // Vérifier le stock disponible
    if (quantity > availableStock) {
      if (!context.mounted) return null;
      NotificationService.showError(
        context,
        'Stock insuffisant. Stock disponible: $availableStock',
      );
      return null;
    }

    onLoadingChanged();

    try {
      final phone = (customerPhone == null || customerPhone.trim().isEmpty)
          ? null
          : (PhoneUtils.normalizeBurkina(customerPhone.trim()) ??
              customerPhone.trim());
      final sale = GasSale(
        id: 'sale-${DateTime.now().millisecondsSinceEpoch}',
        enterpriseId: enterpriseId,
        cylinderId: selectedCylinder.id,
        quantity: quantity,
        unitPrice: unitPrice,
        totalAmount: totalAmount,
        saleDate: DateTime.now(),
        saleType: saleType,
        customerName: customerName,
        customerPhone: phone,
        notes: notes,
        tourId: tourId,
        wholesalerId: wholesalerId,
        wholesalerName: wholesalerName,
        emptyReturnedQuantity: emptyReturnedQuantity,
        dealType: dealType,
        paymentMethod: paymentMethod,
        cashAmount: cashAmount,
        mobileMoneyAmount: mobileMoneyAmount,
      );

      // Exécuter la vente via la transaction atomique (bi-modal stock)
      final transactionService = ref.read(transactionServiceProvider);
      final result = await transactionService.executeSaleTransaction(
        sale: sale,
        weight: selectedCylinder.weight,
        enterpriseId: enterpriseId,
      );

      // Afficher l'alerte de stock si nécessaire (Story 1.4)
      if (result.alert != null) {
        final alertService = ref.read(gasAlertServiceProvider);
        if (context.mounted) {
          alertService.notifyIfLowStock(context, result.alert);
        }
      }

      // Audit Log (Si non géré par la transaction)
      // Note: Pour l'instant on garde l'audit ici pour assurer la compatibilité
      try {
        final auditService = ref.read(auditTrailServiceProvider);
        final authController = ref.read(authControllerProvider);
        final userId = authController.currentUser?.id ?? 'system';
        
        await auditService.logSale(
          enterpriseId: sale.enterpriseId,
          userId: userId,
          saleId: sale.id,
          module: 'gaz',
          totalAmount: sale.totalAmount.toDouble(),
        );
      } catch (e) {
        AppLogger.error('Failed to log gas sale audit in submit handler', error: e);
      }

      if (!context.mounted) return sale;

      // Invalider les providers
      ref.invalidate(gasSalesProvider);
      ref.invalidate(
        cylinderStocksProvider((
          enterpriseId: enterpriseId,
          status: null,
          siteId: null,
        )),
      );

      // Ne pas popper ici, laisser le dialog gérer le succès
      // Navigator.of(context).pop();

      return sale;
    } catch (e, stackTrace) {
      if (!context.mounted) return null;
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Erreur lors de l\'enregistrement de la vente: ${appException.message}',
        name: 'gaz.sale',
        error: e,
        stackTrace: stackTrace,
      );
      NotificationService.showError(
        context,
        ErrorHandler.instance.getUserMessage(appException),
      );
      return null;
    } finally {
      onLoadingChanged();
    }
  }
}
