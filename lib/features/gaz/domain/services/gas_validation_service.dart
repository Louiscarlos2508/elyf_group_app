import '../entities/cylinder.dart';

/// Service for gas sale validation logic.
///
/// Extracts validation logic from UI widgets to make it testable and reusable.
class GasValidationService {
  /// Validates that a cylinder is selected.
  ///
  /// Returns null if valid, error message otherwise.
  static String? validateCylinderSelection(Cylinder? cylinder) {
    if (cylinder == null) {
      return 'Sélectionnez un cylindre';
    }
    return null;
  }

  /// Validates customer name.
  ///
  /// Returns null if valid, error message otherwise.
  static String? validateCustomerName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Le nom du client est requis';
    }
    if (name.trim().length < 2) {
      return 'Le nom doit contenir au moins 2 caractères';
    }
    return null;
  }

  /// Validates customer phone.
  ///
  /// Returns null if valid, error message otherwise.
  static String? validateCustomerPhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return 'Le téléphone du client est requis';
    }
    // Basic phone validation (can be enhanced)
    final phoneRegex = RegExp(r'^[0-9+\-\s()]+$');
    if (!phoneRegex.hasMatch(phone)) {
      return 'Format de téléphone invalide';
    }
    if (phone.replaceAll(RegExp(r'[^0-9]'), '').length < 8) {
      return 'Le numéro de téléphone doit contenir au moins 8 chiffres';
    }
    return null;
  }

  /// Validates that stock is available.
  ///
  /// Returns null if valid, error message otherwise.
  static String? validateStockAvailability({
    required int quantity,
    required int availableStock,
  }) {
    if (quantity > availableStock) {
      return 'Stock insuffisant. Disponible: $availableStock';
    }
    return null;
  }

  /// Validates a complete gas sale.
  ///
  /// Returns a list of validation errors (empty if valid).
  static List<String> validateGasSale({
    required Cylinder? cylinder,
    required int? quantity,
    required int availableStock,
    required String? customerName,
    required String? customerPhone,
  }) {
    final errors = <String>[];

    final cylinderError = validateCylinderSelection(cylinder);
    if (cylinderError != null) errors.add(cylinderError);

    final quantityError = GasCalculationService.validateQuantity(
      quantity: quantity,
      availableStock: availableStock,
    );
    if (quantityError != null) errors.add(quantityError);

    final customerNameError = validateCustomerName(customerName);
    if (customerNameError != null) errors.add(customerNameError);

    final customerPhoneError = validateCustomerPhone(customerPhone);
    if (customerPhoneError != null) errors.add(customerPhoneError);

    return errors;
  }
}

