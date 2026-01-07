import '../../../domain/entities/gas_sale.dart';
import '../../../domain/entities/cylinder.dart';
import '../../../../shared.dart';

/// Helpers pour les calculs et formatage des rapports de vente.
class SalesReportHelpers {
  /// Filtre les ventes par période.
  static List<GasSale> filterSalesByPeriod(
    List<GasSale> sales,
    DateTime startDate,
    DateTime endDate,
  ) {
    return sales.where((s) {
      return s.saleDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          s.saleDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  /// Groupe les ventes par type.
  static ({
    List<GasSale> retail,
    List<GasSale> wholesale,
  }) groupSalesByType(List<GasSale> sales) {
    return (
      retail: sales.where((s) => s.saleType == SaleType.retail).toList(),
      wholesale: sales.where((s) => s.saleType == SaleType.wholesale).toList(),
    );
  }

  /// Calcule le total des ventes.
  static double calculateTotal(List<GasSale> sales) {
    return sales.fold<double>(0, (sum, s) => sum + s.totalAmount);
  }

  /// Calcule la quantité totale.
  static int calculateTotalQuantity(List<GasSale> sales) {
    return sales.fold<int>(0, (sum, s) => sum + s.quantity);
  }

  /// Formate une date de vente.
  static String formatSaleDate(GasSale sale) {
    return '${sale.saleDate.day.toString().padLeft(2, '0')}/${sale.saleDate.month.toString().padLeft(2, '0')}/${sale.saleDate.year} ${sale.saleDate.hour.toString().padLeft(2, '0')}:${sale.saleDate.minute.toString().padLeft(2, '0')}';
  }
}

