import '../entities/cylinder.dart';
import '../entities/gaz_settings.dart';
import '../entities/expense.dart';
import '../entities/gas_sale.dart';
import 'gaz_sales_calculation_service.dart';

class GazFinancialCalculationService {
  GazFinancialCalculationService._();

  static double calculateTotalAmount({
    required Cylinder? cylinder,
    required double unitPrice,
    required int quantity,
    int emptyReturnedQuantity = 0,
  }) {
    if (cylinder == null || (unitPrice == 0.0 && cylinder.depositPrice == 0.0) || quantity < 0) {
      return 0.0;
    }
    
    final gasTotal = unitPrice * quantity;
    final depositDifference = quantity - emptyReturnedQuantity;
    final depositTotal = depositDifference * cylinder.depositPrice;
    
    return gasTotal + depositTotal;
  }

  static double calculateTotalAmountFromText({
    required Cylinder? cylinder,
    required double unitPrice,
    required String? quantityText,
    int emptyReturnedQuantity = 0,
  }) {
    if (cylinder == null ||
        (unitPrice == 0.0 && cylinder.depositPrice == 0.0) ||
        quantityText == null ||
        quantityText.isEmpty) {
      return 0.0;
    }
    final quantity = int.tryParse(quantityText) ?? 0;
    return calculateTotalAmount(
      cylinder: cylinder,
      unitPrice: unitPrice,
      quantity: quantity,
      emptyReturnedQuantity: emptyReturnedQuantity,
    );
  }

  static double calculateProfit({
    required double sellPrice,
    required double? purchasePrice,
    required int quantity,
  }) {
    if (purchasePrice == null || purchasePrice <= 0) {
      return 0.0;
    }
    final profitPerUnit = sellPrice - purchasePrice;
    return profitPerUnit * quantity;
  }

  static double calculateProfitMargin({
    required double sellPrice,
    required double? purchasePrice,
  }) {
    if (sellPrice == 0 || purchasePrice == null || purchasePrice <= 0) {
      return 0.0;
    }
    final profit = sellPrice - purchasePrice;
    return (profit / purchasePrice) * 100;
  }

  static double determineWholesalePrice({
    required Cylinder cylinder,
    required GazSettings? settings,
  }) {
    if (settings == null) {
      return cylinder.sellPrice;
    }
    return settings.getWholesalePrice(cylinder.weight) ?? cylinder.sellPrice;
  }

  static List<GazExpense> calculateTodayExpenses(List<GazExpense> expenses) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return expenses.where((e) {
      final expenseDate = DateTime(e.date.year, e.date.month, e.date.day);
      return expenseDate.isAtSameMomentAs(today);
    }).toList();
  }

  static double calculateTodayExpensesTotal(List<GazExpense> expenses) {
    return calculateTodayExpenses(expenses).fold<double>(0, (sum, e) => sum + e.amount);
  }

  static double calculateTodayProfit(
    List<GasSale> sales,
    List<GazExpense> expenses,
    List<Cylinder> cylinders,
  ) {
    final todaySales = GazSalesCalculationService.calculateTodaySales(sales);
    final todayRevenue = GazSalesCalculationService.calculateTodayRevenue(sales);
    final todayExpenses = calculateTodayExpensesTotal(expenses);
    
    double todayCOGS = 0.0;
    for (final sale in todaySales) {
      final cylinder = cylinders.firstWhere(
        (c) => c.id == sale.cylinderId,
        orElse: () => cylinders.firstWhere((c) => c.weight == 0, orElse: () => cylinders.first),
      );
      todayCOGS += cylinder.buyPrice * sale.quantity;
    }

    return todayRevenue - todayCOGS - todayExpenses;
  }

  static ({
    List<double> profitData,
    List<double> expensesData,
    List<double> salesData,
  })
  calculateLast7DaysPerformance(
    List<GasSale> sales,
    List<GazExpense> expenses,
  ) {
    final now = DateTime.now();
    final profitData = <double>[];
    final expensesData = <double>[];
    final salesData = <double>[];

    for (var i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final daySales = sales.where((s) {
        return s.saleDate.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
            s.saleDate.isBefore(dayEnd);
      }).toList();
      final dayRevenue = daySales.fold<double>(0, (sum, s) => sum + s.totalAmount);
      salesData.add(dayRevenue);

      final dayExpenses = expenses.where((e) {
        return e.date.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
            e.date.isBefore(dayEnd);
      }).toList();
      final dayExpensesAmount = dayExpenses.fold<double>(0, (sum, e) => sum + e.amount);
      expensesData.add(dayExpensesAmount);

      profitData.add(dayRevenue - dayExpensesAmount);
    }

    return (
      profitData: profitData,
      expensesData: expensesData,
      salesData: salesData,
    );
  }

  static double calculateTotalExpenses(List<GazExpense> expenses) {
    return expenses.fold<double>(0, (sum, e) => sum + e.amount);
  }

  static double calculateTotalProfit(List<GasSale> sales, List<GazExpense> expenses) {
    final totalRevenue = GazSalesCalculationService.calculateTotalRevenue(sales);
    final totalExpenses = calculateTotalExpenses(expenses);
    return totalRevenue - totalExpenses;
  }

  static double calculateMonthExpenses(List<GazExpense> expenses, {DateTime? referenceDate}) {
    final now = referenceDate ?? DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthExpenses = expenses.where((e) {
      return e.date.isAfter(monthStart.subtract(const Duration(days: 1)));
    }).toList();
    return monthExpenses.fold<double>(0, (sum, e) => sum + e.amount);
  }

  static double calculateMonthProfit(
    List<GasSale> sales,
    List<GazExpense> expenses,
    List<Cylinder> cylinders, {
    DateTime? referenceDate,
  }) {
    final monthSales = GazSalesCalculationService.calculateMonthSales(sales, referenceDate: referenceDate);
    final monthRevenue = GazSalesCalculationService.calculateMonthRevenue(sales, referenceDate: referenceDate);
    final monthExpenses = calculateMonthExpenses(expenses, referenceDate: referenceDate);
    
    double monthCOGS = 0.0;
    for (final sale in monthSales) {
      final cylinder = cylinders.firstWhere(
        (c) => c.id == sale.cylinderId,
        orElse: () => cylinders.firstWhere((c) => c.weight == 0, orElse: () => cylinders.first),
      );
      monthCOGS += cylinder.buyPrice * sale.quantity;
    }

    return monthRevenue - monthCOGS - monthExpenses;
  }
}
