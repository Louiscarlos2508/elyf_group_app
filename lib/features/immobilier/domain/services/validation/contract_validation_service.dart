import '../../entities/contract.dart';
import '../../entities/property.dart';
import '../../entities/tenant.dart';

/// Service for validating contract data.
///
/// Extracts business logic from UI widgets to make it testable and reusable.
class ContractValidationService {
  ContractValidationService();

  /// Validates that a property is selected.
  bool isPropertySelected(Property? property) {
    return property != null;
  }

  /// Validates that a tenant is selected.
  bool isTenantSelected(Tenant? tenant) {
    return tenant != null;
  }

  /// Validates contract dates.
  String? validateDates({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    if (endDate.isBefore(startDate) || endDate.isAtSameMomentAs(startDate)) {
      return 'La date de fin doit être après la date de début';
    }
    return null;
  }

  /// Calculates deposit amount.
  ///
  /// If depositInMonths is provided and > 0, calculates deposit as monthlyRent * depositInMonths.
  /// Otherwise, uses the provided deposit amount.
  int calculateDeposit({
    required int monthlyRent,
    int? depositInMonths,
    int? depositAmount,
  }) {
    if (depositInMonths != null && depositInMonths > 0) {
      return monthlyRent * depositInMonths;
    }
    return depositAmount ?? 0;
  }
}

