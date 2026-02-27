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
    String? signerName,
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
      signerName: signerName ?? this.signerName,
    );
  }

  factory SalaryPayment.fromMap(Map<String, dynamic> map) {
    return SalaryPayment(
      id: (map['localId'] as String?)?.trim().isNotEmpty == true 
          ? map['localId'] as String 
          : (map['id'] as String? ?? ''),
      employeeId: map['employeeId'] as String,
      employeeName: map['employeeName'] as String,
      amount: (map['amount'] as num).toInt(),
      date: DateTime.parse(map['date'] as String),
      period: map['period'] as String,
      notes: map['notes'] as String?,
      signature: map['signature'] != null
          ? Uint8List.fromList((map['signature'] as List<dynamic>).cast<int>())
          : null,
      signerName: map['signerName'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'amount': amount,
      'date': date.toIso8601String(),
      'period': period,
      'notes': notes,
      'signature': signature?.toList(),
      'signerName': signerName,
    };
  }
}
