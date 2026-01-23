import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import '../../../../../../core/errors/app_exceptions.dart';
import '../../../../../../core/errors/error_handler.dart';
import '../../../../../../core/logging/app_logger.dart';
import '../../../domain/entities/cylinder.dart';
import '../../../domain/entities/gas_sale.dart';

/// Handler pour la soumission du formulaire de vente de gaz.
class GasSaleSubmitHandler {
  GasSaleSubmitHandler._();

  static Future<bool> submit({
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
    required VoidCallback onLoadingChanged,
  }) async {
    // Vérifier le stock disponible
    if (quantity > availableStock) {
      if (!context.mounted) return false;
      NotificationService.showError(
        context,
        'Stock insuffisant. Stock disponible: $availableStock',
      );
      return false;
    }

    onLoadingChanged();

    try {
      final phone = (customerPhone == null || customerPhone.trim().isEmpty)
          ? null
          : (PhoneUtils.normalizeBurkina(customerPhone.trim()) ??
              customerPhone.trim());
      final sale = GasSale(
        id: 'sale-${DateTime.now().millisecondsSinceEpoch}',
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
      );

      // Ajouter la vente
      final gasController = ref.read(gasControllerProvider);
      await gasController.addSale(sale);

      // Mettre à jour le stock: retirer les bouteilles pleines
      final stockController = ref.read(cylinderStockControllerProvider);
      final stocks = await stockController.getStocksByWeight(
        enterpriseId,
        selectedCylinder.weight,
      );

      final fullStock = stocks
          .where((s) => s.status == CylinderStatus.full)
          .firstOrNull;

      if (fullStock != null) {
        final newQuantity = fullStock.quantity - quantity;
        if (newQuantity >= 0) {
          await stockController.adjustStockQuantity(fullStock.id, newQuantity);
        } else {
          throw ValidationException(
            'Stock insuffisant après validation',
            'INSUFFICIENT_STOCK',
          );
        }
      } else {
        throw NotFoundException(
          'Aucun stock disponible trouvé',
          'STOCK_NOT_FOUND',
        );
      }

      if (!context.mounted) return false;

      // Invalider les providers
      ref.invalidate(gasSalesProvider);
      ref.invalidate(
        cylinderStocksProvider((
          enterpriseId: enterpriseId,
          status: null,
          siteId: null,
        )),
      );

      Navigator.of(context).pop();

      NotificationService.showSuccess(
        context,
        'Vente enregistrée avec succès: ${CurrencyFormatter.formatDouble(totalAmount)}',
      );

      return true;
    } catch (e, stackTrace) {
      if (!context.mounted) return false;
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
      return false;
    } finally {
      onLoadingChanged();
    }
  }
}
