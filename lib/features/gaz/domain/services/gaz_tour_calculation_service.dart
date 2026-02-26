import '../entities/collection.dart';
import '../entities/expense.dart';

class GazTourCalculationService {
  GazTourCalculationService._();

  static Map<int, int> calculateTotalBottlesByWeight(List<Collection> collections) {
    final totalBottlesByWeight = <int, int>{};
    for (final collection in collections) {
      for (final entry in collection.emptyBottles.entries) {
        totalBottlesByWeight[entry.key] = (totalBottlesByWeight[entry.key] ?? 0) + entry.value;
      }
    }
    return totalBottlesByWeight;
  }

  static int calculateTotalBottles(List<Collection> collections) {
    final totalBottlesByWeight = calculateTotalBottlesByWeight(collections);
    return totalBottlesByWeight.values.fold<int>(0, (sum, qty) => sum + qty);
  }

  static double calculateTourExpenses(List<GazExpense> expenses, String tourId) {
    return expenses.where((e) => e.tourId == tourId).fold<double>(0, (sum, e) => sum + e.amount);
  }
}
