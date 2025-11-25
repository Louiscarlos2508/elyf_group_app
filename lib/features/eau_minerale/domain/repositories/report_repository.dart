import '../entities/expense_report_data.dart';
import '../entities/product_sales_summary.dart';
import '../entities/production_report_data.dart';
import '../entities/report_data.dart';
import '../entities/report_period.dart';
import '../entities/salary_report_data.dart';
import '../entities/sale.dart';

/// Repository for generating reports.
abstract class ReportRepository {
  Future<ReportData> fetchReportData(ReportPeriod period);
  Future<List<Sale>> fetchSalesForPeriod(ReportPeriod period);
  Future<List<ProductSalesSummary>> fetchProductSalesSummary(ReportPeriod period);
  Future<ProductionReportData> fetchProductionReport(ReportPeriod period);
  Future<ExpenseReportData> fetchExpenseReport(ReportPeriod period);
  Future<SalaryReportData> fetchSalaryReport(ReportPeriod period);
}

