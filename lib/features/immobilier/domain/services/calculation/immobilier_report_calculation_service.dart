
import '../../entities/payment.dart';

class ImmobilierReportCalculationService {
  // Logic for report calculations
  double calculateTotalRevenue(List<Payment> payments) {
    return payments.where((p) => p.status == PaymentStatus.paid)
        .fold(0.0, (sum, p) => sum + p.amount);
  }
}
