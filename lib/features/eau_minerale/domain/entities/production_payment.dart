import 'dart:typed_data';

import 'production_payment_person.dart';

/// Represents a production payment record for weekly workers.
class ProductionPayment {
  const ProductionPayment({
    required this.id,
    required this.period,
    required this.paymentDate,
    required this.persons,
    this.notes,
    this.sourceProductionDayIds = const [],
    this.isVerified = false,
    this.verifiedBy,
    this.verifiedAt,
    this.signature,
  });

  final String id;
  final String period; // e.g., "11-20 novembre 2025"
  final DateTime paymentDate;
  final List<ProductionPaymentPerson> persons;
  final String? notes;

  /// IDs des jours de production sources (traçabilité).
  final List<String> sourceProductionDayIds;

  /// Indique si le paiement a été vérifié et validé.
  final bool isVerified;

  /// ID de la personne qui a vérifié le paiement.
  final String? verifiedBy;

  /// Date de vérification du paiement.
  final DateTime? verifiedAt;

  /// Signature numérique du bénéficiaire (ou du représentant).
  final Uint8List? signature;

  int get totalAmount =>
      persons.fold(0, (sum, p) => sum + p.effectiveTotalAmount);
  int get uniquePersonsCount => persons.length;
}
