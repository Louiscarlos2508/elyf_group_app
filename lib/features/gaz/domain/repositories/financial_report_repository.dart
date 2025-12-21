import '../entities/financial_report.dart';

/// Interface pour le repository des rapports financiers.
abstract class FinancialReportRepository {
  Future<List<FinancialReport>> getReports(
    String enterpriseId, {
    ReportPeriod? period,
    DateTime? from,
    DateTime? to,
    ReportStatus? status,
  });

  Future<FinancialReport?> getReportById(String id);

  Future<String> generateReport(FinancialReport report);

  Future<void> updateReport(FinancialReport report);

  Future<void> finalizeReport(String reportId);

  Future<double> calculateNetAmount(
    String enterpriseId,
    DateTime startDate,
    DateTime endDate,
  );

  Future<void> deleteReport(String id);
}