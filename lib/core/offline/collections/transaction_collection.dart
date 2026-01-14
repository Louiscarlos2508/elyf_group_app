/// Legacy TransactionCollection model (kept for compatibility).
/// Note: Drift est utilisé exclusivement pour le stockage offline (pas ObjectBox).
class TransactionCollection {
  int id = 0;
  late String localId;
  String? remoteId;
  late String enterpriseId;
  late String agentId;
  late String transactionType;
  double amount = 0;
  double commission = 0;
  String? customerName;
  String? customerPhone;
  String? reference;
  String? notes;
  late DateTime transactionDate;
  DateTime? createdAt;
  DateTime? updatedAt;
  late DateTime localUpdatedAt;

  TransactionCollection();

  /// Creates a TransactionCollection from a map.
  factory TransactionCollection.fromMap(
    Map<String, dynamic> map, {
    required String enterpriseId,
    required String localId,
  }) {
    final collection = TransactionCollection()
      ..localId = localId
      ..enterpriseId = enterpriseId
      ..agentId = map['agentId'] as String? ?? ''
      ..transactionType =
          map['transactionType'] as String? ??
          map['type'] as String? ??
          'cashIn'
      ..amount = (map['amount'] as num?)?.toDouble() ?? 0
      ..commission = (map['commission'] as num?)?.toDouble() ?? 0
      ..customerName = map['customerName'] as String?
      ..customerPhone = map['customerPhone'] as String?
      ..reference = map['reference'] as String?
      ..notes = map['notes'] as String?
      ..transactionDate = map['transactionDate'] != null
          ? DateTime.parse(map['transactionDate'] as String)
          : (map['date'] != null
                ? DateTime.parse(map['date'] as String)
                : DateTime.now())
      ..localUpdatedAt = DateTime.now();
    return collection;
  }

  Map<String, dynamic> toMap() => {
    'id': remoteId ?? localId,
    'localId': localId,
    'enterpriseId': enterpriseId,
    'agentId': agentId,
    'transactionType': transactionType,
    'type': transactionType,
    'amount': amount,
    'commission': commission,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'reference': reference,
    'notes': notes,
    'transactionDate': transactionDate.toIso8601String(),
    'date': transactionDate.toIso8601String(),
  };
}
