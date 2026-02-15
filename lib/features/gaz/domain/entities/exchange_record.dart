/// Représente un échange de bouteilles (inter-marques ou non-standard).
class ExchangeRecord {
  const ExchangeRecord({
    required this.id,
    required this.enterpriseId,
    required this.fromCylinderId, // Bouteille donnée
    required this.toCylinderId, // Bouteille reçue
    required this.quantity,
    required this.exchangedAt,
    this.notes,
    this.reportedBy,
  });

  final String id;
  final String enterpriseId;
  final String fromCylinderId;
  final String toCylinderId;
  final int quantity;
  final DateTime exchangedAt;
  final String? notes;
  final String? reportedBy;

  ExchangeRecord copyWith({
    String? id,
    String? enterpriseId,
    String? fromCylinderId,
    String? toCylinderId,
    int? quantity,
    DateTime? exchangedAt,
    String? notes,
    String? reportedBy,
  }) {
    return ExchangeRecord(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      fromCylinderId: fromCylinderId ?? this.fromCylinderId,
      toCylinderId: toCylinderId ?? this.toCylinderId,
      quantity: quantity ?? this.quantity,
      exchangedAt: exchangedAt ?? this.exchangedAt,
      notes: notes ?? this.notes,
      reportedBy: reportedBy ?? this.reportedBy,
    );
  }

  factory ExchangeRecord.fromMap(Map<String, dynamic> map) {
    return ExchangeRecord(
      id: map['id'] as String,
      enterpriseId: map['enterpriseId'] as String,
      fromCylinderId: map['fromCylinderId'] as String,
      toCylinderId: map['toCylinderId'] as String,
      quantity: (map['quantity'] as num).toInt(),
      exchangedAt: DateTime.parse(map['exchangedAt'] as String),
      notes: map['notes'] as String?,
      reportedBy: map['reportedBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'fromCylinderId': fromCylinderId,
      'toCylinderId': toCylinderId,
      'quantity': quantity,
      'exchangedAt': exchangedAt.toIso8601String(),
      'notes': notes,
      'reportedBy': reportedBy,
    };
  }
}
