/// Stub ExpenseCollection - Isar temporarily disabled.
/// TODO: Migrate to ObjectBox.
class ExpenseCollection {
  int id = 0;
  late String localId;
  String? remoteId;
  late String enterpriseId;
  late String moduleType;
  late String category;
  late String description;
  double amount = 0;
  late DateTime expenseDate;
  String? paymentMethod;
  String? reference;
  String? notes;
  DateTime? createdAt;
  DateTime? updatedAt;
  late DateTime localUpdatedAt;

  ExpenseCollection();

  /// Creates an ExpenseCollection from a map.
  factory ExpenseCollection.fromMap(
    Map<String, dynamic> map, {
    required String enterpriseId,
    required String moduleType,
    required String localId,
  }) {
    final collection = ExpenseCollection()
      ..localId = localId
      ..enterpriseId = enterpriseId
      ..moduleType = moduleType
      ..category = map['category'] as String? ?? ''
      ..description = map['description'] as String? ?? ''
      ..amount = (map['amount'] as num?)?.toDouble() ?? 0
      ..expenseDate = map['expenseDate'] != null
          ? DateTime.parse(map['expenseDate'] as String)
          : (map['date'] != null
              ? DateTime.parse(map['date'] as String)
              : DateTime.now())
      ..paymentMethod = map['paymentMethod'] as String?
      ..reference = map['reference'] as String?
      ..notes = map['notes'] as String?
      ..localUpdatedAt = DateTime.now();
    return collection;
  }

  Map<String, dynamic> toMap() => {
        'id': remoteId ?? localId,
        'localId': localId,
        'enterpriseId': enterpriseId,
        'moduleType': moduleType,
        'category': category,
        'description': description,
        'amount': amount,
        'expenseDate': expenseDate.toIso8601String(),
        'date': expenseDate.toIso8601String(),
        'paymentMethod': paymentMethod,
        'reference': reference,
        'notes': notes,
      };
}
