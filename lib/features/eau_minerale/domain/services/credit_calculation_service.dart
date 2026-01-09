import '../entities/credit_payment.dart';
import '../entities/customer_credit.dart';

/// Service for credit calculation logic.
///
/// Extracts calculation logic from UI widgets to make it testable and reusable.
class CreditCalculationService {
  /// Calculates total credit from a list of credits.
  static int calculateTotalCredit(List<CustomerCredit> credits) {
    return credits.fold(0, (sum, credit) => sum + credit.remainingAmount);
  }

  /// Calculates total paid from a list of payments.
  static int calculateTotalPaid(List<CreditPayment> payments) {
    return payments.fold(0, (sum, payment) => sum + payment.amount);
  }

  /// Calculates remaining credit after payments.
  static int calculateRemainingCredit({
    required int initialCredit,
    required int totalPaid,
  }) {
    final remaining = initialCredit - totalPaid;
    return remaining > 0 ? remaining : 0;
  }

  /// Validates that payment amount doesn't exceed remaining credit.
  ///
  /// Returns null if valid, error message otherwise.
  static String? validatePaymentAmount({
    required int? paymentAmount,
    required int remainingCredit,
  }) {
    if (paymentAmount == null) {
      return 'Le montant est requis';
    }
    if (paymentAmount <= 0) {
      return 'Le montant doit être supérieur à 0';
    }
    if (paymentAmount > remainingCredit) {
      return 'Le montant ne peut pas dépasser le crédit restant (${remainingCredit} FCFA)';
    }
    return null;
  }

  /// Checks if credit is fully paid.
  static bool isCreditFullyPaid(int remainingCredit) {
    return remainingCredit <= 0;
  }

  /// Calculates payment percentage.
  static double calculatePaymentPercentage({
    required int totalPaid,
    required int initialCredit,
  }) {
    if (initialCredit <= 0) return 0.0;
    return (totalPaid / initialCredit) * 100;
  }
}

