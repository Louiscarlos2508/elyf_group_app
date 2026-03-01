import '../../entities/payment.dart';
import '../../entities/expense.dart';

class ImmobilierReportCalculationService {
  // Logic for report calculations
  double calculateTotalRevenue(List<Payment> payments) {
    return payments.where((p) => p.status == PaymentStatus.paid)
        .fold(0.0, (sum, p) => sum + p.amount.toDouble());
  }

  double calculateTotalExpenses(List<PropertyExpense> expenses) {
    return expenses.fold(0.0, (sum, e) => sum + e.amount.toDouble());
  }
}
