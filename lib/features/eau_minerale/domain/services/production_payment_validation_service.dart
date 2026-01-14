import '../entities/production_payment_person.dart';

/// Service for validating production payment data.
///
/// Extracts validation logic from UI widgets to make it testable and reusable.
class ProductionPaymentValidationService {
  ProductionPaymentValidationService();

  /// Validates that at least one person is added.
  bool validateHasPersons(List<ProductionPaymentPerson> persons) {
    return persons.isNotEmpty;
  }

  /// Validates that all persons have valid names.
  bool validateAllPersonNames(List<ProductionPaymentPerson> persons) {
    return persons.every((person) => person.name.trim().isNotEmpty);
  }

  /// Validates that all persons have valid amounts and days.
  bool validateAllPersonAmountsAndDays(List<ProductionPaymentPerson> persons) {
    return persons.every(
      (person) => person.pricePerDay > 0 && person.daysWorked > 0,
    );
  }

  /// Validates a single person's data.
  bool validatePerson(ProductionPaymentPerson person) {
    return person.name.trim().isNotEmpty &&
        person.pricePerDay > 0 &&
        person.daysWorked > 0;
  }

  /// Gets validation error message for persons list.
  String? getPersonsValidationError(List<ProductionPaymentPerson> persons) {
    if (!validateHasPersons(persons)) {
      return 'Ajoutez au moins une personne à payer';
    }
    if (!validateAllPersonNames(persons)) {
      return 'Tous les noms doivent être remplis';
    }
    if (!validateAllPersonAmountsAndDays(persons)) {
      return 'Vérifiez les montants et jours';
    }
    return null;
  }
}
