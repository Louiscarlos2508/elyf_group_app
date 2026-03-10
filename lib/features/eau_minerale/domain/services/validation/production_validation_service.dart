import '../../entities/machine.dart';
import '../../entities/machine_material_usage.dart';

/// Service for validating production data.
///
/// Extracts business logic from UI widgets to make it testable and reusable.
class ProductionValidationService {
  ProductionValidationService();

  /// Validates that a machine is selected.
  String? validateMachineSelection(Machine? machine) {
    if (machine == null) {
      return 'Sélectionnez une machine';
    }
    return null;
  }

  /// Validates that at least one machine is selected.
  static String? validateMachinesSelection(List<String> machines) {
    if (machines.isEmpty) {
      return 'Sélectionnez au moins une machine';
    }
    return null;
  }

  /// Validates that machine material stocks are available.
  bool hasAvailableMachineMaterialStocks(List<dynamic> machineMaterialStocks) {
    return machineMaterialStocks.isNotEmpty;
  }

  /// Validates that all active machines have an associated material.
  static String? validateMachinesAndMaterials(
    List<String> machinesSelectionnees,
    List<MachineMaterialUsage> materials,
  ) {
    if (machinesSelectionnees.isEmpty) {
      return 'Veuillez au moins sélectionner une machine';
    }
    if (materials.isEmpty) {
      return 'Veuillez au moins ajouter une matière';
    }
    if (materials.length < machinesSelectionnees.length) {
      return 'Chaque machine doit avoir une matière installée';
    }
    return null;
  }

  /// Validates that the meter index is provided.
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
  static String? validateTimeRange({
    required DateTime startTime,
    DateTime? endTime,
  }) {
    if (endTime != null && endTime.isBefore(startTime)) {
      return 'L\'heure de fin doit être après l\'heure de début';
    }
    return null;
  }

  /// Validates product name.
  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le nom du produit est requis';
    }
    if (value.trim().length < 2) {
      return 'Le nom doit contenir au moins 2 caractères';
    }
    return null;
  }

  /// Validates product price.
  String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le prix est requis';
    }
    final price = double.tryParse(value);
    if (price == null) {
      return 'Le prix doit être un nombre valide';
    }
    if (price < 0) {
      return 'Le prix doit être positif';
    }
    return null;
  }

  /// Validates product unit.
  String? validateUnit(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'L\'unité est requise';
    }
    if (value.trim().isEmpty) {
      return 'L\'unité doit contenir au moins 1 caractère';
    }
    return null;
  }
}
