import '../../domain/entities/expense.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/entities/report_data.dart';
import '../../domain/entities/sale.dart';

class ReportCalculator {
  static DateTime getStartDate(ReportPeriod period, DateTime? startDate) {
    if (startDate != null) return startDate;
    final now = DateTime.now();
    switch (period) {
      case ReportPeriod.today:
        return DateTime(now.year, now.month, now.day);
      case ReportPeriod.week:
        return now.subtract(Duration(days: now.weekday - 1));
      case ReportPeriod.month:
        return DateTime(now.year, now.month, 1);
      case ReportPeriod.year:
        return DateTime(now.year, 1, 1);
      case ReportPeriod.custom:
        return startDate ?? now.subtract(const Duration(days: 30));
    }
  }

  static DateTime getEndDate(ReportPeriod period, DateTime? endDate) {
    if (endDate != null) return endDate;
    return DateTime.now();
  }

  static List<Sale> filterSales(
    List<Sale> sales,
    DateTime start,
    DateTime end,
  ) {
    return sales.where((s) {
      return s.date.isAfter(start.subtract(const Duration(days: 1))) &&
          s.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  static List<Purchase> filterPurchases(
    List<Purchase> purchases,
    DateTime start,
    DateTime end,
  ) {
    return purchases.where((p) {
      return p.date.isAfter(start.subtract(const Duration(days: 1))) &&
          p.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  static List<Expense> filterExpenses(
    List<Expense> expenses,
    DateTime start,
    DateTime end,
  ) {
    return expenses.where((e) {
      return e.date.isAfter(start.subtract(const Duration(days: 1))) &&
          e.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  static String getCategoryName(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.stock:
        return 'Stock/Achats';
      case ExpenseCategory.rent:
        return 'Loyer';
      case ExpenseCategory.utilities:
        return 'Services publics';
      case ExpenseCategory.maintenance:
        return 'Maintenance';
      case ExpenseCategory.marketing:
        return 'Marketing';
      case ExpenseCategory.other:
        return 'Autres';
    }
  }
}

