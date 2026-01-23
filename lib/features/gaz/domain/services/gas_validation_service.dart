import 'package:elyf_groupe_app/shared.dart';

import '../entities/cylinder.dart';
import 'gas_calculation_service.dart';

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

  /// Validates customer phone (Burkina +226).
  ///
  /// Returns null if valid, error message otherwise.
  static String? validateCustomerPhone(String? phone) {
    return PhoneUtils.validateBurkina(
      phone,
      customMessage: 'Le téléphone du client est requis',
    );
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
