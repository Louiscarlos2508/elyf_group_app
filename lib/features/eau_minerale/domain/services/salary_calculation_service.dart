/// Service for salary calculation logic.
///
/// Extracts calculation logic from UI widgets to make it testable and reusable.
class SalaryCalculationService {
  /// Calculates total salary from a list of salary amounts.
  static int calculateTotalSalary(List<int> salaries) {
    return salaries.fold(0, (sum, salary) => sum + salary);
  }

  /// Calculates total days worked from a list of days.
  static int calculateTotalDaysWorked(List<int> days) {
    return days.fold(0, (sum, days) => sum + days);
  }

  /// Calculates total salary from a map of salary info.
  ///
  /// The map values should have a `totalSalary` property.
  static int calculateTotalFromMap<T>(Map<String, T> salaries, int Function(T) getSalary) {
    return salaries.values.fold(0, (sum, info) => sum + getSalary(info));
  }

  /// Calculates total days from a map of salary info.
  ///
  /// The map values should have a `daysWorked` property.
  static int calculateTotalDaysFromMap<T>(Map<String, T> salaries, int Function(T) getDays) {
    return salaries.values.fold(0, (sum, info) => sum + getDays(info));
  }

  /// Calculates total salary from a list of salary info objects.
  ///
  /// The list items should have a `totalSalary` property.
  static int calculateTotalFromList<T>(List<T> salaries, int Function(T) getSalary) {
    return salaries.fold(0, (sum, info) => sum + getSalary(info));
  }

  /// Calculates total days from a list of salary info objects.
  ///
  /// The list items should have a `daysWorked` property.
  static int calculateTotalDaysFromList<T>(List<T> salaries, int Function(T) getDays) {
    return salaries.fold(0, (sum, info) => sum + getDays(info));
  }
}

