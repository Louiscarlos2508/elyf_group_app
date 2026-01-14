import '../../domain/entities/expense_report_data.dart';
import '../../domain/entities/product_sales_summary.dart';
import '../../domain/entities/production_report_data.dart';
import '../../domain/entities/report_data.dart';
import '../../domain/entities/report_period.dart';
import '../../domain/entities/salary_report_data.dart';
import '../../domain/entities/sale.dart';
import '../../domain/repositories/report_repository.dart';

class ReportController {
  ReportController(this._repository);

  final ReportRepository _repository;

  Future<ReportData> fetchReportData(ReportPeriod period) async {
    return await _repository.fetchReportData(period);
  }

  Future<List<Sale>> fetchSalesForPeriod(ReportPeriod period) async {
    return await _repository.fetchSalesForPeriod(period);
  }

  Future<List<ProductSalesSummary>> fetchProductSalesSummary(
    ReportPeriod period,
  ) async {
    return await _repository.fetchProductSalesSummary(period);
  }

  Future<ProductionReportData> fetchProductionReport(
    ReportPeriod period,
  ) async {
    return await _repository.fetchProductionReport(period);
  }

  Future<ExpenseReportData> fetchExpenseReport(ReportPeriod period) async {
    return await _repository.fetchExpenseReport(period);
  }

  Future<SalaryReportData> fetchSalaryReport(ReportPeriod period) async {
    return await _repository.fetchSalaryReport(period);
  }
}
