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

  Future<FullBoutiqueReportData> getFullReportData(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<ProfitReportData> getProfitReport(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  });
  
  Stream<ReportData> watchReportData(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  });

  Stream<SalesReportData> watchSalesReport(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  });

  Stream<PurchasesReportData> watchPurchasesReport(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  });

  Stream<ExpensesReportData> watchExpensesReport(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  });

  Stream<ProfitReportData> watchProfitReport(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  });

  Stream<FullBoutiqueReportData> watchFullReportData(
    ReportPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<DebtsReportData> getDebtsReport();
  Stream<DebtsReportData> watchDebtsReport();
}
