import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../shared/utils/currency_formatter.dart';
import '../../../../application/controllers/cylinder_stock_controller.dart';
import '../../../../application/providers.dart';
import '../../../../domain/entities/cylinder.dart';
import '../../../../domain/entities/cylinder_stock.dart';
import '../../../../domain/entities/gas_sale.dart';

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
    required VoidCallback onLoadingChanged,
  }) async {
    // Vérifier le stock disponible
    if (quantity > availableStock) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Stock insuffisant. Stock disponible: $availableStock',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    onLoadingChanged();

    try {
      final sale = GasSale(
        id: 'sale-${DateTime.now().millisecondsSinceEpoch}',
        cylinderId: selectedCylinder.id,
        quantity: quantity,
        unitPrice: selectedCylinder.sellPrice,
        totalAmount: totalAmount,
        saleDate: DateTime.now(),
        saleType: saleType,
        customerName: customerName,
        customerPhone: customerPhone,
        notes: notes,
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
          await stockController.adjustStockQuantity(
            fullStock.id,
            newQuantity,
          );
        } else {
          throw Exception('Stock insuffisant après validation');
        }
      } else {
        throw Exception('Aucun stock disponible trouvé');
      }

      if (!context.mounted) return false;

      // Invalider les providers
      ref.invalidate(gasSalesProvider);
      ref.invalidate(
        cylinderStocksProvider(
          (
            enterpriseId: enterpriseId,
            status: null,
            siteId: null,
          ),
        ),
      );

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vente enregistrée avec succès: ${CurrencyFormatter.formatDouble(totalAmount)}',
          ),
          backgroundColor: Colors.green,
        ),
      );

      return true;
    } catch (e) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    } finally {
      onLoadingChanged();
    }
  }
}

