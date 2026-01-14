import '../../../domain/entities/gas_sale.dart';

/// Helpers pour le formatage des rapports de vente.
///
/// Note: Les calculs sont maintenant dans GazReportCalculationService.
/// Ce helper ne contient que le formatage pour l'affichage.
class SalesReportHelpers {
  /// Calcule la quantité totale (utilisé pour l'affichage uniquement).
  ///
  /// Note: Pour les calculs métier, utiliser GazReportCalculationService.
  static int calculateTotalQuantity(List<GasSale> sales) {
    return sales.fold<int>(0, (sum, s) => sum + s.quantity);
  }

  /// Formate une date de vente.
  static String formatSaleDate(GasSale sale) {
    return '${sale.saleDate.day.toString().padLeft(2, '0')}/${sale.saleDate.month.toString().padLeft(2, '0')}/${sale.saleDate.year} ${sale.saleDate.hour.toString().padLeft(2, '0')}:${sale.saleDate.minute.toString().padLeft(2, '0')}';
  }
}
