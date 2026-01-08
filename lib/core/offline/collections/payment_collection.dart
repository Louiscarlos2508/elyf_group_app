/// Legacy PaymentCollection model (kept for compatibility).
/// Note: Drift est utilisé exclusivement pour le stockage offline (pas ObjectBox).
class PaymentCollection {
  int id = 0;
  late String localId;
  String? remoteId;
  late String enterpriseId;
  late String contractId;
  double amount = 0;
  late DateTime paymentDate;
  String paymentMethod = 'cash';
  String? reference;
  String? notes;
  DateTime? createdAt;
  DateTime? updatedAt;
  late DateTime localUpdatedAt;

  PaymentCollection();

  /// Creates a PaymentCollection from a map.
  factory PaymentCollection.fromMap(
    Map<String, dynamic> map, {
    required String enterpriseId,
    required String localId,
  }) {
    final collection = PaymentCollection()
      ..localId = localId
      ..enterpriseId = enterpriseId
      ..contractId = map['contractId'] as String? ?? ''
      ..amount = (map['amount'] as num?)?.toDouble() ?? 0
      ..paymentDate = map['paymentDate'] != null
          ? DateTime.parse(map['paymentDate'] as String)
          : (map['date'] != null
              ? DateTime.parse(map['date'] as String)
              : DateTime.now())
      ..paymentMethod = map['paymentMethod'] as String? ?? 'cash'
      ..reference = map['reference'] as String?
      ..notes = map['notes'] as String?
      ..localUpdatedAt = DateTime.now();
    return collection;
  }

  Map<String, dynamic> toMap() => {
        'id': remoteId ?? localId,
        'localId': localId,
        'enterpriseId': enterpriseId,
        'contractId': contractId,
        'amount': amount,
        'paymentDate': paymentDate.toIso8601String(),
        'date': paymentDate.toIso8601String(),
        'paymentMethod': paymentMethod,
        'reference': reference,
        'notes': notes,
      };
}
