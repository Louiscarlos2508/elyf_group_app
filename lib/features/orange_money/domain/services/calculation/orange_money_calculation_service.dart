/// Service for calculating metrics for the Orange Money module.
///
/// Extracts business logic from UI widgets to make it testable and reusable.
class OrangeMoneyCalculationService {
  OrangeMoneyCalculationService();

  /// Calculates total from a list of amounts.
  int calculateTotal(List<int> amounts) {
    return amounts.fold(0, (sum, amount) => sum + amount);
  }

  /// Calculates average from a list of amounts.
  double calculateAverage(List<int> amounts) {
    if (amounts.isEmpty) return 0.0;
    final total = calculateTotal(amounts);
    return total / amounts.length;
  }

  /// Calculates percentage.
  double calculatePercentage({required int part, required int total}) {
    if (total == 0) return 0.0;
    return (part / total) * 100;
  }
}
