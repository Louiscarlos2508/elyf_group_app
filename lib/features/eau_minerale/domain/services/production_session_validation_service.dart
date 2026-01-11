import '../entities/bobine_usage.dart';

/// Service for validating production session data.
///
/// Extracts validation logic from UI widgets to make it testable and reusable.
class ProductionSessionValidationService {
  /// Validates that at least one machine is selected.
  ///
  /// Returns null if valid, error message otherwise.
  static String? validateMachinesSelection(List<String> machines) {
    if (machines.isEmpty) {
      return 'Sélectionnez au moins une machine';
    }
    return null;
  }

  /// Validates that the number of bobines matches the number of machines.
  ///
  /// Returns null if valid, error message otherwise.
  static String? validateMachinesAndBobines({
    required List<String> machines,
    required List<BobineUsage> bobines,
  }) {
    if (machines.isEmpty) {
      return 'Sélectionnez au moins une machine';
    }
    if (bobines.length != machines.length) {
      return 'Le nombre de bobines (${bobines.length}) doit être égal au nombre de machines (${machines.length})';
    }
    return null;
  }

  /// Validates that the meter index is provided.
  ///
  /// Returns null if valid, error message otherwise.
  static String? validateMeterIndex({
    required String? indexText,
    required String meterLabel,
  }) {
    if (indexText == null || indexText.trim().isEmpty) {
      return 'L\'${meterLabel.toLowerCase()} est requis';
    }
    return null;
  }

  /// Validates that the quantity produced is valid.
  ///
  /// Returns null if valid, error message otherwise.
  static String? validateQuantity(int? quantity) {
    if (quantity == null) {
      return 'La quantité est requise';
    }
    if (quantity < 0) {
      return 'La quantité ne peut pas être négative';
    }
    return null;
  }

  /// Validates that the consumption is valid.
  ///
  /// Returns null if valid, error message otherwise.
  static String? validateConsumption(double? consumption) {
    if (consumption == null) {
      return 'La consommation est requise';
    }
    if (consumption < 0) {
      return 'La consommation ne peut pas être négative';
    }
    return null;
  }

  /// Validates that the start time is before end time.
  ///
  /// Returns null if valid, error message otherwise.
  static String? validateTimeRange({
    required DateTime startTime,
    DateTime? endTime,
  }) {
    if (endTime != null && endTime.isBefore(startTime)) {
      return 'L\'heure de fin doit être après l\'heure de début';
    }
    return null;
  }

  /// Validates all production session data.
  ///
  /// Returns a list of validation errors (empty if valid).
  static List<String> validateProductionSession({
    required List<String> machines,
    required List<BobineUsage> bobines,
    required String? meterIndexText,
    required String meterLabel,
    required int? quantity,
    required double? consumption,
    required DateTime startTime,
    DateTime? endTime,
  }) {
    final errors = <String>[];

    final machinesError = validateMachinesAndBobines(
      machines: machines,
      bobines: bobines,
    );
    if (machinesError != null) {
      errors.add(machinesError);
    }

    final meterError = validateMeterIndex(
      indexText: meterIndexText,
      meterLabel: meterLabel,
    );
    if (meterError != null) {
      errors.add(meterError);
    }

    final quantityError = validateQuantity(quantity);
    if (quantityError != null) {
      errors.add(quantityError);
    }

    final consumptionError = validateConsumption(consumption);
    if (consumptionError != null) {
      errors.add(consumptionError);
    }

    final timeError = validateTimeRange(
      startTime: startTime,
      endTime: endTime,
    );
    if (timeError != null) {
      errors.add(timeError);
    }

    return errors;
  }
}

