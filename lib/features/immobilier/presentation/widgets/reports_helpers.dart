import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/report_period.dart';

/// Helpers pour les rapports.
///
/// Utilise les formatters partagés pour éviter la duplication.
class ReportsHelpers {
  ReportsHelpers._();

  static String formatCurrency(int amount) {
    return CurrencyFormatter.formatShort(amount);
  }

  static List<Payment> getPaymentsInPeriod(
    List<Payment> payments,
    ReportPeriod period,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    if (period == ReportPeriod.custom && startDate != null && endDate != null) {
      return payments.where((p) {
        return p.paymentDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
            p.paymentDate.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
    }

    final now = DateTime.now();
    DateTime periodStart;

    switch (period) {
      case ReportPeriod.today:
        periodStart = DateTime(now.year, now.month, now.day);
        break;
      case ReportPeriod.thisWeek:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        periodStart = DateTime(weekStart.year, weekStart.month, weekStart.day);
        break;
      case ReportPeriod.thisMonth:
        periodStart = DateTime(now.year, now.month, 1);
        break;
      case ReportPeriod.thisYear:
        periodStart = DateTime(now.year, 1, 1);
        break;
      case ReportPeriod.custom:
        periodStart = startDate ?? now;
    }

    return payments.where((p) {
      return p.paymentDate.isAfter(periodStart.subtract(const Duration(days: 1)));
    }).toList();
  }

  static List<PropertyExpense> getExpensesInPeriod(
    List<PropertyExpense> expenses,
    ReportPeriod period,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    if (period == ReportPeriod.custom && startDate != null && endDate != null) {
      return expenses.where((e) {
        return e.expenseDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
            e.expenseDate.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
    }

    final now = DateTime.now();
    DateTime periodStart;

    switch (period) {
      case ReportPeriod.today:
        periodStart = DateTime(now.year, now.month, now.day);
        break;
      case ReportPeriod.thisWeek:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        periodStart = DateTime(weekStart.year, weekStart.month, weekStart.day);
        break;
      case ReportPeriod.thisMonth:
        periodStart = DateTime(now.year, now.month, 1);
        break;
      case ReportPeriod.thisYear:
        periodStart = DateTime(now.year, 1, 1);
        break;
      case ReportPeriod.custom:
        periodStart = startDate ?? now;
    }

    return expenses.where((e) {
      return e.expenseDate.isAfter(periodStart.subtract(const Duration(days: 1)));
    }).toList();
  }
}

