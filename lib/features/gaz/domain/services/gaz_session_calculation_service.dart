import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';
import '../entities/cylinder.dart';
import '../entities/cylinder_stock.dart';
import '../entities/expense.dart';
import '../entities/gas_sale.dart';
import '../entities/gaz_session.dart';
import 'gaz_stock_calculation_service.dart';

class SessionMetrics {
  final int totalSales;
  final double totalRevenue;
  final double latestCash;
  final double latestMobileMoney;
  final Map<int, int> salesByWeight;

  SessionMetrics({
    required this.totalSales,
    required this.totalRevenue,
    required this.latestCash,
    required this.latestMobileMoney,
    required this.salesByWeight,
  });
}

class ReconciliationMetrics {
  final double initialCash;
  final double initialMobileMoney;
  final double totalCashSales;
  final double totalMobileMoneySales;
  final double totalExpenses;
  final double theoreticalCash;
  final double theoreticalMobileMoney;
  final double totalSales;
  final Map<PaymentMethod, double> salesByPaymentMethod;
  final Map<int, int> salesByCylinderWeight;
  final Map<int, int> theoreticalStock;
  final Map<int, int> theoreticalEmptyStock;
  final DateTime date;

  ReconciliationMetrics({
    required this.initialCash,
    required this.initialMobileMoney,
    required this.totalCashSales,
    required this.totalMobileMoneySales,
    required this.totalExpenses,
    required this.theoreticalCash,
    required this.theoreticalMobileMoney,
    required this.totalSales,
    required this.salesByPaymentMethod,
    required this.salesByCylinderWeight,
    required this.theoreticalStock,
    required this.theoreticalEmptyStock,
    required this.date,
  });
}

class GazSessionCalculationService {
  GazSessionCalculationService._();

  static SessionMetrics calculateSessionMetrics({
    required GazSession session,
    required List<GasSale> allSales,
    required List<Cylinder> cylinders,
  }) {
    final sessionSales = allSales.where((s) => s.sessionId == session.id).toList();

    final totalSales = sessionSales.length;
    final totalRevenue = sessionSales.fold<double>(0, (sum, s) => sum + s.totalAmount);

    final cashSales = sessionSales
        .where((s) => s.paymentMethod == PaymentMethod.cash)
        .fold<double>(0, (sum, s) => sum + s.totalAmount);
        
    final mobileMoneySales = sessionSales
        .where((s) => s.paymentMethod == PaymentMethod.mobileMoney)
        .fold<double>(0, (sum, s) => sum + s.totalAmount);

    final latestCash = session.openingCash + cashSales;
    final latestMobileMoney = session.openingMobileMoney + mobileMoneySales;

    final salesByWeight = <int, int>{};
    for (final sale in sessionSales) {
      final cylinder = cylinders.firstWhere((c) => c.id == sale.cylinderId, orElse: () => cylinders.first);
      salesByWeight[cylinder.weight] = (salesByWeight[cylinder.weight] ?? 0) + sale.quantity;
    }

    return SessionMetrics(
      totalSales: totalSales,
      totalRevenue: totalRevenue,
      latestCash: latestCash,
      latestMobileMoney: latestMobileMoney,
      salesByWeight: salesByWeight,
    );
  }

  static ReconciliationMetrics calculateDailyReconciliation({
    required DateTime date,
    required List<GasSale> allSales,
    required List<GazExpense> allExpenses,
    required List<Cylinder> cylinders,
    List<CylinderStock> stocks = const [],
    double openingCash = 0.0,
    double openingMobileMoney = 0.0,
  }) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final todaySales = allSales.where((s) {
      return s.saleDate.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
          s.saleDate.isBefore(dayEnd);
    }).toList();

    final todayExpenses = allExpenses.where((e) {
      return e.date.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
          e.date.isBefore(dayEnd);
    }).toList();

    final totalExpenses = todayExpenses.fold<double>(0, (sum, e) => sum + e.amount);

    final salesByPaymentMethod = <PaymentMethod, double>{};
    for (final method in PaymentMethod.values) {
      salesByPaymentMethod[method] = todaySales
          .where((s) => s.paymentMethod == method)
          .fold<double>(0, (sum, s) => sum + s.totalAmount);
    }

    final cashSales = salesByPaymentMethod[PaymentMethod.cash] ?? 0.0;
    final theoreticalCash = openingCash + cashSales - totalExpenses;

    final mobileMoneySales = salesByPaymentMethod[PaymentMethod.mobileMoney] ?? 0.0;
    final theoreticalMobileMoney = openingMobileMoney + mobileMoneySales;

    final totalSales = todaySales.fold<double>(0, (sum, s) => sum + s.totalAmount);

    final salesByCylinderWeight = <int, int>{};
    for (final sale in todaySales) {
      final cylinder = cylinders.firstWhere((c) => c.id == sale.cylinderId, orElse: () => cylinders.first);
      salesByCylinderWeight[cylinder.weight] = (salesByCylinderWeight[cylinder.weight] ?? 0) + sale.quantity;
    }

    final theoreticalStock = GazStockCalculationService.groupStocksByWeight(GazStockCalculationService.filterFullStocks(stocks));
    final theoreticalEmptyStock = GazStockCalculationService.groupStocksByWeight(GazStockCalculationService.filterEmptyStocks(stocks));

    return ReconciliationMetrics(
      initialCash: openingCash,
      initialMobileMoney: openingMobileMoney,
      totalCashSales: cashSales,
      totalMobileMoneySales: mobileMoneySales,
      totalExpenses: totalExpenses,
      theoreticalCash: theoreticalCash,
      theoreticalMobileMoney: theoreticalMobileMoney,
      totalSales: totalSales,
      salesByPaymentMethod: salesByPaymentMethod,
      salesByCylinderWeight: salesByCylinderWeight,
      theoreticalStock: theoreticalStock,
      theoreticalEmptyStock: theoreticalEmptyStock,
      date: date,
    );
  }
}
