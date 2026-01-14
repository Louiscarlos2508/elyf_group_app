import 'package:intl/intl.dart';

/// Service for commission calculation logic.
///
/// Extracts calculation logic from UI widgets to make it testable and reusable.
class CommissionCalculationService {
  /// Formats a period from DateTime to string (yyyy-MM).
  static String formatPeriod(DateTime month) {
    return DateFormat('yyyy-MM').format(month);
  }

  /// Formats a period for display (e.g., "Janvier 2024").
  static String formatPeriodForDisplay(
    DateTime month, [
    String locale = 'fr_FR',
  ]) {
    return DateFormat('MMMM yyyy', locale).format(month);
  }

  /// Validates commission amount.
  ///
  /// Returns null if valid, error message otherwise.
  static String? validateAmount(int? amount) {
    if (amount == null) {
      return 'Le montant est requis';
    }
    if (amount <= 0) {
      return 'Le montant doit être supérieur à 0';
    }
    if (amount > 100000000) {
      return 'Le montant semble trop élevé (max 100,000,000 FCFA)';
    }
    return null;
  }

  /// Validates commission period.
  ///
  /// Returns null if valid, error message otherwise.
  static String? validatePeriod(DateTime? period) {
    if (period == null) {
      return 'Veuillez sélectionner un mois';
    }
    final now = DateTime.now();
    if (period.isAfter(now)) {
      return 'La période ne peut pas être dans le futur';
    }
    return null;
  }

  /// Calculates total commissions for a list of amounts.
  static int calculateTotal(List<int> amounts) {
    return amounts.fold(0, (sum, amount) => sum + amount);
  }

  /// Calculates average commission.
  static double? calculateAverage(List<int> amounts) {
    if (amounts.isEmpty) return null;
    return calculateTotal(amounts) / amounts.length;
  }
}
