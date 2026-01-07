import '../entities/production_session.dart';
import '../entities/sale.dart';

/// Service for calculating profitability metrics.
///
/// Extracts business logic from UI widgets to make it testable and reusable.
class ProfitabilityCalculationService {
  ProfitabilityCalculationService();

  /// Calculates all profitability metrics.
  ProfitabilityMetrics calculateMetrics({
    required List<ProductionSession> sessions,
    required List<Sale> sales,
    required int totalExpenses,
  }) {
    final totalProduction =
        sessions.fold<int>(0, (sum, s) => sum + s.quantiteProduite);
    final totalProductionCost =
        sessions.fold<int>(0, (sum, s) => sum + s.coutTotal);
    final totalRevenue = sales.fold<int>(0, (sum, s) => sum + s.totalPrice);
    final totalSalesQuantity =
        sales.fold<int>(0, (sum, s) => sum + s.quantity);

    final costPerUnit =
        totalProduction > 0 ? totalProductionCost / totalProduction : 0.0;
    final avgSalePrice =
        totalSalesQuantity > 0 ? totalRevenue / totalSalesQuantity : 0.0;
    final marginPerUnit = avgSalePrice - costPerUnit;
    final totalCosts = totalProductionCost + totalExpenses;
    final grossProfit = totalRevenue - totalCosts;
    final grossMarginPercent =
        totalRevenue > 0 ? (grossProfit / totalRevenue) * 100 : 0.0;

    return ProfitabilityMetrics(
      totalProduction: totalProduction,
      totalProductionCost: totalProductionCost,
      totalRevenue: totalRevenue,
      totalSalesQuantity: totalSalesQuantity,
      costPerUnit: costPerUnit,
      avgSalePrice: avgSalePrice,
      marginPerUnit: marginPerUnit,
      totalCosts: totalCosts,
      grossProfit: grossProfit,
      grossMarginPercent: grossMarginPercent,
    );
  }

  /// Analyzes sales by product.
  List<ProductProfitAnalysis> analyzeByProduct(List<Sale> sales) {
    final byProduct = <String, Map<String, dynamic>>{};

    for (final sale in sales) {
      final name = sale.productName;
      if (!byProduct.containsKey(name)) {
        byProduct[name] = {
          'name': name,
          'quantity': 0,
          'revenue': 0,
        };
      }
      byProduct[name]!['quantity'] =
          (byProduct[name]!['quantity'] as int) + sale.quantity;
      byProduct[name]!['revenue'] =
          (byProduct[name]!['revenue'] as int) + sale.totalPrice;
    }

    final result = byProduct.values.map((product) {
      final revenue = product['revenue'] as int;
      final estimatedCost = (revenue * 0.75).toInt();
      final margin = revenue - estimatedCost;
      final marginPercent = revenue > 0 ? (margin / revenue) * 100 : 0.0;

      return ProductProfitAnalysis(
        productName: product['name'] as String,
        quantity: product['quantity'] as int,
        revenue: revenue,
        estimatedCost: estimatedCost,
        margin: margin,
        marginPercent: marginPercent,
      );
    }).toList();

    result.sort((a, b) => b.margin.compareTo(a.margin));
    return result;
  }
}

/// Profitability metrics data class.
class ProfitabilityMetrics {
  const ProfitabilityMetrics({
    required this.totalProduction,
    required this.totalProductionCost,
    required this.totalRevenue,
    required this.totalSalesQuantity,
    required this.costPerUnit,
    required this.avgSalePrice,
    required this.marginPerUnit,
    required this.totalCosts,
    required this.grossProfit,
    required this.grossMarginPercent,
  });

  final int totalProduction;
  final int totalProductionCost;
  final int totalRevenue;
  final int totalSalesQuantity;
  final double costPerUnit;
  final double avgSalePrice;
  final double marginPerUnit;
  final int totalCosts;
  final int grossProfit;
  final double grossMarginPercent;
}

/// Product profitability analysis data class.
class ProductProfitAnalysis {
  const ProductProfitAnalysis({
    required this.productName,
    required this.quantity,
    required this.revenue,
    required this.estimatedCost,
    required this.margin,
    required this.marginPercent,
  });

  final String productName;
  final int quantity;
  final int revenue;
  final int estimatedCost;
  final int margin;
  final double marginPercent;
}





