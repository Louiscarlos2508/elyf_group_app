import '../../domain/entities/financial_report.dart';
import '../../domain/repositories/financial_report_repository.dart';
import '../../domain/services/financial_calculation_service.dart';

/// Contrôleur pour la gestion des rapports financiers.
class FinancialReportController {
  FinancialReportController(
    this._repository,
    this._calculationService,
  );

  final FinancialReportRepository _repository;
  final FinancialCalculationService _calculationService;

  /// Récupère les rapports.
  Future<List<FinancialReport>> getReports(
    String enterpriseId, {
    ReportPeriod? period,
    DateTime? from,
    DateTime? to,
    ReportStatus? status,
  }) async {
    return _repository.getReports(
      enterpriseId,
      period: period,
      from: from,
      to: to,
      status: status,
    );
  }

  /// Récupère un rapport par ID.
  Future<FinancialReport?> getReportById(String id) async {
    return _repository.getReportById(id);
  }

  /// Génère un rapport financier pour une période.
  Future<String> generateReport(
    String enterpriseId,
    ReportPeriod period,
    DateTime reportDate,
    double totalRevenue,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Calculer les charges
    final charges = await _calculationService.calculateCharges(
      enterpriseId,
      startDate,
      endDate,
    );

    // Calculer le reliquat net
    final netAmount = await _calculationService.calculateNetAmount(
      enterpriseId,
      startDate,
      endDate,
      totalRevenue,
    );

    final report = FinancialReport(
      id: '',
      enterpriseId: enterpriseId,
      reportDate: reportDate,
      period: period,
      totalRevenue: totalRevenue,
      totalExpenses: charges.totalExpenses,
      loadingEventExpenses: charges.loadingEventExpenses,
      fixedCharges: charges.fixedCharges,
      variableCharges: charges.variableCharges,
      salaries: charges.salaries,
      netAmount: netAmount,
      status: ReportStatus.draft,
    );

    return _repository.generateReport(report);
  }

  /// Finalise un rapport.
  Future<void> finalizeReport(String reportId) async {
    await _repository.finalizeReport(reportId);
  }

  /// Calcule le reliquat net pour une période (pour versement siège).
  Future<double> calculateNetAmount(
    String enterpriseId,
    DateTime startDate,
    DateTime endDate,
    double totalRevenue,
  ) async {
    return _calculationService.calculateNetAmount(
      enterpriseId,
      startDate,
      endDate,
      totalRevenue,
    );
  }
}