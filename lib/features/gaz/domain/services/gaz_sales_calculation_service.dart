import '../entities/gas_sale.dart';
import '../entities/cylinder.dart';

class WholesaleMetrics {
  final int salesCount;
  final double totalSold;
  final double collected;
  final double credit;
  final List<GasSale> sales;

  WholesaleMetrics({
    required this.salesCount,
    required this.totalSold,
    required this.collected,
    required this.credit,
    required this.sales,
  });
}

class RetailMetrics {
  final int todaySalesCount;
  final double todayRevenue;
  final Map<int, int> salesByWeight;

  RetailMetrics({
    required this.todaySalesCount,
    required this.todayRevenue,
    required this.salesByWeight,
  });
}

class GazSalesCalculationService {
  GazSalesCalculationService._();

  static String? validateQuantity({required int? quantity, required int availableStock}) {
    if (quantity == null) return 'Veuillez entrer une quantité';
    if (quantity <= 0) return 'Quantité invalide';
    if (quantity > availableStock) return 'Stock insuffisant ($availableStock disponible)';
    return null;
  }

  static String? validateQuantityText({required String? quantityText, required int availableStock}) {
    if (quantityText == null || quantityText.isEmpty) return 'Veuillez entrer une quantité';
    return validateQuantity(quantity: int.tryParse(quantityText), availableStock: availableStock);
  }

  static List<GasSale> filterSalesByDateRange(List<GasSale> sales, {DateTime? startDate, DateTime? endDate}) {
    if (startDate == null && endDate == null) return sales;
    final start = startDate ?? DateTime(2020);
    final end = endDate ?? DateTime.now();

    return sales.where((s) {
      final saleDate = DateTime(s.saleDate.year, s.saleDate.month, s.saleDate.day);
      return saleDate.isAfter(start.subtract(const Duration(days: 1))) &&
          saleDate.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  static List<GasSale> filterSalesByType(List<GasSale> sales, SaleType saleType) {
    return sales.where((s) => s.saleType == saleType).toList();
  }

  static List<GasSale> filterWholesaleSales(List<GasSale> sales) => filterSalesByType(sales, SaleType.wholesale);
  static List<GasSale> filterRetailSales(List<GasSale> sales) => filterSalesByType(sales, SaleType.retail);

  static WholesaleMetrics calculateWholesaleMetrics(List<GasSale> allSales, {DateTime? startDate, DateTime? endDate, bool isWholesaleOnly = true}) {
    final baseSales = isWholesaleOnly ? filterWholesaleSales(allSales) : allSales;
    final filteredSales = filterSalesByDateRange(baseSales, startDate: startDate, endDate: endDate);

    final totalSold = filteredSales.fold<double>(0, (sum, s) => sum + s.totalAmount);
    return WholesaleMetrics(
      salesCount: filteredSales.length,
      totalSold: totalSold,
      collected: totalSold, // TODO: Update with payment status if added
      credit: 0.0,
      sales: filteredSales,
    );
  }

  static RetailMetrics calculateRetailMetrics(List<GasSale> allSales, List<Cylinder> cylinders, {DateTime? referenceDate}) {
    final now = referenceDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todaySales = filterRetailSales(allSales).where((s) => 
        DateTime(s.saleDate.year, s.saleDate.month, s.saleDate.day).isAtSameMomentAs(today)).toList();

    final todayRevenue = todaySales.fold<double>(0, (sum, s) => sum + s.totalAmount);
    final salesByWeight = { for (var c in cylinders) c.weight: 0 };
    
    for (final sale in todaySales) {
      final cylinder = cylinders.firstWhere((c) => c.id == sale.cylinderId, orElse: () => cylinders.first);
      salesByWeight[cylinder.weight] = (salesByWeight[cylinder.weight] ?? 0) + sale.quantity;
    }

    return RetailMetrics(todaySalesCount: todaySales.length, todayRevenue: todayRevenue, salesByWeight: salesByWeight);
  }

  static List<GasSale> calculateTodaySales(List<GasSale> sales) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return sales.where((s) {
      final saleDate = DateTime(s.saleDate.year, s.saleDate.month, s.saleDate.day);
      return saleDate.isAtSameMomentAs(today);
    }).toList();
  }

  static double calculateTodayRevenue(List<GasSale> sales) {
    return calculateTodaySales(sales).fold<double>(0, (sum, s) => sum + s.totalAmount);
  }

  static List<GasSale> calculateTodaySalesByType(List<GasSale> sales, SaleType saleType) {
    return calculateTodaySales(filterSalesByType(sales, saleType));
  }

  static double calculateTodayRevenueByType(List<GasSale> sales, SaleType saleType) {
    return calculateTodaySalesByType(sales, saleType).fold<double>(0, (sum, s) => sum + s.totalAmount);
  }

  static List<GasSale> calculateMonthSales(List<GasSale> sales, {DateTime? referenceDate}) {
    final now = referenceDate ?? DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    return sales.where((s) => s.saleDate.isAfter(monthStart.subtract(const Duration(days: 1)))).toList();
  }

  static double calculateMonthRevenue(List<GasSale> sales, {DateTime? referenceDate}) {
    return calculateMonthSales(sales, referenceDate: referenceDate).fold<double>(0, (sum, s) => sum + s.totalAmount);
  }

  static double calculateTotalRevenue(List<GasSale> sales) {
    return sales.fold<double>(0, (sum, s) => sum + s.totalAmount);
  }
}
