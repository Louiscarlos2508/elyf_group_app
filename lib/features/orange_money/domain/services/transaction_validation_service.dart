/// Service for transaction validation logic.
///
/// Extracts validation logic from UI widgets to make it testable and reusable.
class TransactionValidationService {
  /// Validates transaction amount.
  ///
  /// Returns null if valid, error message otherwise.
  static String? validateAmount(int? amount) {
    if (amount == null) {
      return 'Le montant est requis';
    }
    if (amount <= 0) {
      return 'Le montant doit être supérieur à 0';
    }
    if (amount > 100000000) {
      return 'Le montant semble trop élevé (max 100,000,000 FCFA)';
    }
    return null;
  }

  /// Validates phone number.
  ///
  /// Returns null if valid, error message otherwise.
  static String? validatePhoneNumber(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return 'Le numéro de téléphone est requis';
    }
    // Basic phone validation for Orange Money (typically starts with specific prefixes)
    final cleanedPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanedPhone.length < 8) {
      return 'Le numéro de téléphone doit contenir au moins 8 chiffres';
    }
    if (cleanedPhone.length > 15) {
      return 'Le numéro de téléphone est trop long';
    }
    return null;
  }

  /// Validates transaction reference.
  ///
  /// Returns null if valid, error message otherwise.
  static String? validateReference(String? reference) {
    if (reference == null || reference.trim().isEmpty) {
      return 'La référence est requise';
    }
    if (reference.trim().length < 5) {
      return 'La référence doit contenir au moins 5 caractères';
    }
    return null;
  }

  /// Validates transaction date.
  ///
  /// Returns null if valid, error message otherwise.
  static String? validateDate(DateTime? date) {
    if (date == null) {
      return 'La date est requise';
    }
    final now = DateTime.now();
    if (date.isAfter(now)) {
      return 'La date ne peut pas être dans le futur';
    }
    // Allow transactions up to 1 year in the past
    final oneYearAgo = DateTime(now.year - 1, now.month, now.day);
    if (date.isBefore(oneYearAgo)) {
      return 'La date ne peut pas être antérieure à 1 an';
    }
    return null;
  }

  /// Validates agent ID.
  ///
  /// Returns null if valid, error message otherwise.
  static String? validateAgentId(String? agentId) {
    if (agentId == null || agentId.trim().isEmpty) {
      return 'L\'ID de l\'agent est requis';
    }
    return null;
  }

  /// Validates a complete transaction.
  ///
  /// Returns a list of validation errors (empty if valid).
  static List<String> validateTransaction({
    required int? amount,
    required String? phoneNumber,
    required String? reference,
    required DateTime? date,
    String? agentId,
  }) {
    final errors = <String>[];

    final amountError = validateAmount(amount);
    if (amountError != null) errors.add(amountError);

    final phoneError = validatePhoneNumber(phoneNumber);
    if (phoneError != null) errors.add(phoneError);

    final referenceError = validateReference(reference);
    if (referenceError != null) errors.add(referenceError);

    final dateError = validateDate(date);
    if (dateError != null) errors.add(dateError);

    if (agentId != null) {
      final agentIdError = validateAgentId(agentId);
      if (agentIdError != null) errors.add(agentIdError);
    }

    return errors;
  }
}
