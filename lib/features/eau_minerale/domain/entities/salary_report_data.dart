import 'production_payment.dart';
import 'salary_payment.dart';

/// Represents salary report data for a period.
class SalaryReportData {
  const SalaryReportData({
    required this.totalMonthlySalaries,
    required this.totalProductionPayments,
    required this.totalAmount,
    required this.monthlyPayments,
    required this.productionPayments,
  });

  final int totalMonthlySalaries; // Total for fixed employees
  final int totalProductionPayments; // Total for production workers
  final int totalAmount; // Grand total
  final List<SalaryPayment> monthlyPayments; // Monthly salary payments
  final List<ProductionPayment> productionPayments; // Production payments
}

