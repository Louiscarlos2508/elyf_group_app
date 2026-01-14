import '../../entities/machine.dart';

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

  /// Validates that bobine stocks are available.
  bool hasAvailableBobineStocks(List<dynamic> bobineStocks) {
    return bobineStocks.isNotEmpty;
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
