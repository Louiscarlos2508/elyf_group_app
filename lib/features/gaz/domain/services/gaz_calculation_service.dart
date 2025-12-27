import '../entities/collection.dart';
import '../entities/expense.dart';
import '../entities/gas_sale.dart';

/// Service de calculs métier pour le module gaz.
class GazCalculationService {
  GazCalculationService._();

  /// Calcule les ventes du jour.
  static List<GasSale> calculateTodaySales(List<GasSale> sales) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return sales.where((s) {
      final saleDate = DateTime(
        s.saleDate.year,
        s.saleDate.month,
        s.saleDate.day,
      );
      return saleDate.isAtSameMomentAs(today);
    }).toList();
  }

  /// Calcule le revenu du jour.
  static double calculateTodayRevenue(List<GasSale> sales) {
    final todaySales = calculateTodaySales(sales);
    return todaySales.fold<double>(0, (sum, s) => sum + s.totalAmount);
  }

  /// Calcule les ventes du jour par type.
  static List<GasSale> calculateTodaySalesByType(
    List<GasSale> sales,
    SaleType saleType,
  ) {
    final todaySales = calculateTodaySales(sales);
    return todaySales.where((s) => s.saleType == saleType).toList();
  }

  /// Calcule le revenu du jour par type.
  static double calculateTodayRevenueByType(
    List<GasSale> sales,
    SaleType saleType,
  ) {
    final todaySalesByType = calculateTodaySalesByType(sales, saleType);
    return todaySalesByType.fold<double>(
      0.0,
      (sum, sale) => sum + sale.totalAmount,
    );
  }

  /// Calcule les dépenses du jour.
  static List<GazExpense> calculateTodayExpenses(List<GazExpense> expenses) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return expenses.where((e) {
      final expenseDate = DateTime(e.date.year, e.date.month, e.date.day);
      return expenseDate.isAtSameMomentAs(today);
    }).toList();
  }

  /// Calcule le total des dépenses du jour.
  static double calculateTodayExpensesTotal(List<GazExpense> expenses) {
    final todayExpenses = calculateTodayExpenses(expenses);
    return todayExpenses.fold<double>(0, (sum, e) => sum + e.amount);
  }

  /// Calcule le profit du jour.
  static double calculateTodayProfit(
    List<GasSale> sales,
    List<GazExpense> expenses,
  ) {
    final todayRevenue = calculateTodayRevenue(sales);
    final todayExpenses = calculateTodayExpensesTotal(expenses);
    return todayRevenue - todayExpenses;
  }

  /// Calcule les données de performance pour les 7 derniers jours.
  static ({
    List<double> profitData,
    List<double> expensesData,
    List<double> salesData,
  }) calculateLast7DaysPerformance(
    List<GasSale> sales,
    List<GazExpense> expenses,
  ) {
    final now = DateTime.now();
    final profitData = <double>[];
    final expensesData = <double>[];
    final salesData = <double>[];

    // Calculate data for last 7 days
    for (var i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      // Sales for this day
      final daySales = sales.where((s) {
        return s.saleDate.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
            s.saleDate.isBefore(dayEnd);
      }).toList();
      final dayRevenue =
          daySales.fold<double>(0, (sum, s) => sum + s.totalAmount);
      salesData.add(dayRevenue);

      // Expenses for this day
      final dayExpenses = expenses.where((e) {
        return e.date.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
            e.date.isBefore(dayEnd);
      }).toList();
      final dayExpensesAmount =
          dayExpenses.fold<double>(0, (sum, e) => sum + e.amount);
      expensesData.add(dayExpensesAmount);

      // Profit for this day
      final dayProfit = dayRevenue - dayExpensesAmount;
      profitData.add(dayProfit);
    }

    return (
      profitData: profitData,
      expensesData: expensesData,
      salesData: salesData,
    );
  }

  /// Calcule le total des bouteilles par poids à partir des collections.
  static Map<int, int> calculateTotalBottlesByWeight(
    List<Collection> collections,
  ) {
    final totalBottlesByWeight = <int, int>{};
    for (final collection in collections) {
      for (final entry in collection.emptyBottles.entries) {
        totalBottlesByWeight[entry.key] =
            (totalBottlesByWeight[entry.key] ?? 0) + entry.value;
      }
    }
    return totalBottlesByWeight;
  }

  /// Calcule le total général des bouteilles à partir des collections.
  static int calculateTotalBottles(List<Collection> collections) {
    final totalBottlesByWeight = calculateTotalBottlesByWeight(collections);
    return totalBottlesByWeight.values.fold<int>(0, (sum, qty) => sum + qty);
  }

  /// Calcule le total général des dépenses.
  static double calculateTotalExpenses(List<GazExpense> expenses) {
    return expenses.fold<double>(0, (sum, e) => sum + e.amount);
  }

  /// Calcule le revenu total.
  static double calculateTotalRevenue(List<GasSale> sales) {
    return sales.fold<double>(0, (sum, s) => sum + s.totalAmount);
  }

  /// Calcule le profit total.
  static double calculateTotalProfit(
    List<GasSale> sales,
    List<GazExpense> expenses,
  ) {
    final totalRevenue = calculateTotalRevenue(sales);
    final totalExpenses = calculateTotalExpenses(expenses);
    return totalRevenue - totalExpenses;
  }
}

