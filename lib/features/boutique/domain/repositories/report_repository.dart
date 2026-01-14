import '../entities/report_data.dart';

/// Repository for generating reports.
abstract class ReportRepository {
  Future<ReportData> getReportData(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<SalesReportData> getSalesReport(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<PurchasesReportData> getPurchasesReport(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<ExpensesReportData> getExpensesReport(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<ProfitReportData> getProfitReport(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  });
}
