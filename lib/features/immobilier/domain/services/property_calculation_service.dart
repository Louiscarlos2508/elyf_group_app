/// Service for property calculation logic.
///
/// Extracts calculation logic from UI widgets to make it testable and reusable.
class PropertyCalculationService {
  /// Calculates deposit amount from number of months.
  ///
  /// Returns 0 if monthlyRent is null or months is invalid.
  static int calculateDeposit({
    required int? monthlyRent,
    required int? months,
  }) {
    if (monthlyRent == null || months == null || months <= 0) {
      return 0;
    }
    return monthlyRent * months;
  }

  /// Calculates deposit amount from months text input.
  ///
  /// Returns 0 if monthlyRent is null or monthsText is invalid.
  static int calculateDepositFromMonths({
    required int? monthlyRent,
    required String? monthsText,
  }) {
    if (monthlyRent == null || monthsText == null || monthsText.isEmpty) {
      return 0;
    }
    final months = int.tryParse(monthsText);
    if (months == null || months <= 0) {
      return 0;
    }
    return calculateDeposit(monthlyRent: monthlyRent, months: months);
  }

  /// Calculates total rent for a period.
  static int calculateTotalRent({
    required int monthlyRent,
    required int numberOfMonths,
  }) {
    if (numberOfMonths <= 0) return 0;
    return monthlyRent * numberOfMonths;
  }

  /// Calculates rent per square meter.
  static double? calculateRentPerSquareMeter({
    required int monthlyRent,
    required int? area,
  }) {
    if (area == null || area <= 0) return null;
    return monthlyRent / area;
  }

  /// Validates that deposit amount is reasonable.
  ///
  /// Returns null if valid, error message otherwise.
  static String? validateDepositAmount({
    required int? depositAmount,
    required int? monthlyRent,
  }) {
    if (depositAmount == null) {
      return 'Le montant de la caution est requis';
    }
    if (depositAmount < 0) {
      return 'Le montant de la caution ne peut pas être négatif';
    }
    if (monthlyRent != null && depositAmount > monthlyRent * 12) {
      return 'La caution ne devrait pas dépasser 12 mois de loyer';
    }
    return null;
  }

  /// Validates that number of months for deposit is reasonable.
  ///
  /// Returns null if valid, error message otherwise.
  static String? validateDepositMonths(int? months) {
    if (months == null) {
      return 'Le nombre de mois est requis';
    }
    if (months <= 0) {
      return 'Le nombre de mois doit être supérieur à 0';
    }
    if (months > 12) {
      return 'La caution ne devrait pas dépasser 12 mois';
    }
    return null;
  }
}

