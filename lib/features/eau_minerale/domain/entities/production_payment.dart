import 'production_payment_person.dart';

/// Represents a production payment record for weekly workers.
class ProductionPayment {
  const ProductionPayment({
    required this.id,
    required this.period,
    required this.paymentDate,
    required this.persons,
    this.notes,
  });

  final String id;
  final String period; // e.g., "11-20 novembre 2025"
  final DateTime paymentDate;
  final List<ProductionPaymentPerson> persons;
  final String? notes;

  int get totalAmount => persons.fold(0, (sum, p) => sum + p.effectiveTotalAmount);
  int get uniquePersonsCount => persons.length;
}

