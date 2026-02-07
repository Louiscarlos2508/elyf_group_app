import 'dart:typed_data';

/// Represents a salary payment record.
class SalaryPayment {
  const SalaryPayment({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.amount,
    required this.date,
    required this.period,
    this.notes,
    this.signature, // Signature numérique du bénéficiaire
    this.signerName, // Nom du signataire
  });

  final String id;
  final String employeeId;
  final String employeeName;
  final int amount;
  final DateTime date;
  final String period;
  final String? notes;
  final Uint8List? signature; // Signature numérique en format PNG
  final String? signerName; // Nom de la personne qui a signé

  /// Vérifie si le paiement a une signature
  bool get aSignature => signature != null && signature!.isNotEmpty;

  SalaryPayment copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    int? amount,
    DateTime? date,
    String? period,
    String? notes,
    Uint8List? signature,
  }) {
    return SalaryPayment(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      period: period ?? this.period,
      notes: notes ?? this.notes,
      signature: signature ?? this.signature,
    );
  }
}
