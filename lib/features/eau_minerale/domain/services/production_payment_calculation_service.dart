import '../entities/production_payment_person.dart';

/// Service pour calculer les montants de paiement de production.
///
/// Extrait la logique métier des widgets pour la rendre testable et réutilisable.
class ProductionPaymentCalculationService {
  ProductionPaymentCalculationService();

  /// Calcule le montant total à partir du prix par jour et du nombre de jours.
  ///
  /// [pricePerDay] : Prix par jour en FCFA
  /// [daysWorked] : Nombre de jours travaillés
  /// Retourne le montant total calculé
  int calculateTotalAmount({
    required int pricePerDay,
    required int daysWorked,
  }) {
    if (pricePerDay <= 0 || daysWorked <= 0) return 0;
    return pricePerDay * daysWorked;
  }

  /// Calcule le prix par jour à partir du montant total et du nombre de jours.
  ///
  /// [totalAmount] : Montant total en FCFA
  /// [daysWorked] : Nombre de jours travaillés
  /// Retourne le prix par jour calculé (arrondi)
  int calculatePricePerDay({
    required int totalAmount,
    required int daysWorked,
  }) {
    if (totalAmount <= 0 || daysWorked <= 0) return 0;
    return (totalAmount / daysWorked).round();
  }

  /// Met à jour une personne de paiement avec les nouveaux calculs.
  ///
  /// Si le total est calculé automatiquement, il sera mis à jour.
  /// Si le total est saisi manuellement, le prix par jour sera recalculé.
  ProductionPaymentPerson updatePersonCalculations({
    required ProductionPaymentPerson person,
    int? newPricePerDay,
    int? newDaysWorked,
    int? newTotalAmount,
  }) {
    final pricePerDay = newPricePerDay ?? person.pricePerDay;
    final daysWorked = newDaysWorked ?? person.daysWorked;

    // Si le total est fourni manuellement et que les jours sont fournis, recalculer le prix par jour
    if (newTotalAmount != null && newTotalAmount > 0 && daysWorked > 0) {
      final calculatedPricePerDay = calculatePricePerDay(
        totalAmount: newTotalAmount,
        daysWorked: daysWorked,
      );
      return person.copyWith(
        pricePerDay: calculatedPricePerDay,
        daysWorked: daysWorked,
        totalAmount: newTotalAmount,
      );
    }

    // Sinon, calculer le total à partir du prix par jour et des jours
    if (pricePerDay > 0 && daysWorked > 0) {
      final calculatedTotal = calculateTotalAmount(
        pricePerDay: pricePerDay,
        daysWorked: daysWorked,
      );
      return person.copyWith(
        pricePerDay: pricePerDay,
        daysWorked: daysWorked,
        totalAmount: null, // Auto-calculé, pas besoin de stocker
      );
    }

    // Par défaut, retourner la personne avec les valeurs mises à jour
    return person.copyWith(
      pricePerDay: pricePerDay,
      daysWorked: daysWorked,
      totalAmount: newTotalAmount,
    );
  }
}

