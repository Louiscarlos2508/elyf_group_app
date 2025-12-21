import 'dart:math';
import '../../domain/entities/financial_report.dart';
import '../../domain/repositories/financial_report_repository.dart';

/// Implémentation mock du repository des rapports financiers.
class MockFinancialReportRepository implements FinancialReportRepository {
  final List<FinancialReport> _reports = [];
  final Random _random = Random();

  @override
  Future<List<FinancialReport>> getReports(
    String enterpriseId, {
    ReportPeriod? period,
    DateTime? from,
    DateTime? to,
    ReportStatus? status,
  }) async {
    return _reports.where((r) {
      if (r.enterpriseId != enterpriseId) return false;
      if (period != null && r.period != period) return false;
      if (status != null && r.status != status) return false;
      if (from != null && r.reportDate.isBefore(from)) return false;
      if (to != null && r.reportDate.isAfter(to)) return false;
      return true;
    }).toList();
  }

  @override
  Future<FinancialReport?> getReportById(String id) async {
    return _reports.where((r) => r.id == id).firstOrNull;
  }

  @override
  Future<String> generateReport(FinancialReport report) async {
    final id = report.id.isEmpty
        ? 'report_${_random.nextInt(1000000)}'
        : report.id;
    final newReport = report.copyWith(id: id);
    _reports.add(newReport);
    return id;
  }

  @override
  Future<void> updateReport(FinancialReport report) async {
    final index = _reports.indexWhere((r) => r.id == report.id);
    if (index != -1) {
      _reports[index] = report;
    }
  }

  @override
  Future<void> finalizeReport(String reportId) async {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index != -1) {
      _reports[index] =
          _reports[index].copyWith(status: ReportStatus.finalized);
    }
  }

  @override
  Future<double> calculateNetAmount(
    String enterpriseId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // En mock, on calcule à partir des rapports existants
    final reports = await getReports(
      enterpriseId,
      from: startDate,
      to: endDate,
    );
    if (reports.isEmpty) return 0.0;
    return reports
        .map((r) => r.netAmount)
        .fold<double>(0.0, (sum, amount) => sum + amount);
  }

  @override
  Future<void> deleteReport(String id) async {
    _reports.removeWhere((r) => r.id == id);
  }
}