/// Represents a liquidity checkpoint (pointage de liquidité).
class LiquidityCheckpoint {
  const LiquidityCheckpoint({
    required this.id,
    required this.enterpriseId,
    required this.date,
    required this.type,
    required this.amount,
    this.morningCheckpoint,
    this.eveningCheckpoint,
    this.cashAmount, // Montant en cash (FCFA) - pour compatibilité
    this.simAmount, // Solde sur la SIM (FCFA) - pour compatibilité
    this.morningCashAmount, // Cash du pointage du matin (FCFA)
    this.morningSimAmount, // SIM du pointage du matin (FCFA)
    this.eveningCashAmount, // Cash du pointage du soir (FCFA)
    this.eveningSimAmount, // SIM du pointage du soir (FCFA)
    this.notes,
    this.deletedAt,
    this.deletedBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String enterpriseId;
  final DateTime date;
  final LiquidityCheckpointType type;
  final int amount; // Montant total en FCFA (cash + sim)
  final int? morningCheckpoint; // Pointage du matin en FCFA (total)
  final int? eveningCheckpoint; // Pointage du soir en FCFA (total)
  final int? cashAmount; // Montant en cash (FCFA) - pour compatibilité
  final int? simAmount; // Solde sur la SIM (FCFA) - pour compatibilité
  final int? morningCashAmount; // Cash du pointage du matin (FCFA)
  final int? morningSimAmount; // SIM du pointage du matin (FCFA)
  final int? eveningCashAmount; // Cash du pointage du soir (FCFA)
  final int? eveningSimAmount; // SIM du pointage du soir (FCFA)
  final String? notes;
  final DateTime? deletedAt;
  final String? deletedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isDeleted => deletedAt != null;

  /// Vérifie si le pointage du matin est effectué.
  bool get hasMorningCheckpoint =>
      (morningCashAmount != null && morningCashAmount! > 0) ||
      (morningSimAmount != null && morningSimAmount! > 0);

  /// Vérifie si le pointage du soir est effectué.
  bool get hasEveningCheckpoint =>
      (eveningCashAmount != null && eveningCashAmount! > 0) ||
      (eveningSimAmount != null && eveningSimAmount! > 0);

  /// Vérifie si les deux pointages sont effectués.
  bool get isComplete => hasMorningCheckpoint && hasEveningCheckpoint;

  LiquidityCheckpoint copyWith({
    String? id,
    String? enterpriseId,
    DateTime? date,
    LiquidityCheckpointType? type,
    int? amount,
    int? morningCheckpoint,
    int? eveningCheckpoint,
    int? cashAmount,
    int? simAmount,
    int? morningCashAmount,
    int? morningSimAmount,
    int? eveningCashAmount,
    int? eveningSimAmount,
    String? notes,
    DateTime? deletedAt,
    String? deletedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LiquidityCheckpoint(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      date: date ?? this.date,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      morningCheckpoint: morningCheckpoint ?? this.morningCheckpoint,
      eveningCheckpoint: eveningCheckpoint ?? this.eveningCheckpoint,
      cashAmount: cashAmount ?? this.cashAmount,
      simAmount: simAmount ?? this.simAmount,
      morningCashAmount: morningCashAmount ?? this.morningCashAmount,
      morningSimAmount: morningSimAmount ?? this.morningSimAmount,
      eveningCashAmount: eveningCashAmount ?? this.eveningCashAmount,
      eveningSimAmount: eveningSimAmount ?? this.eveningSimAmount,
      notes: notes ?? this.notes,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory LiquidityCheckpoint.fromMap(
    Map<String, dynamic> map,
    String defaultEnterpriseId,
  ) {
    return LiquidityCheckpoint(
      id: map['id'] as String? ?? map['localId'] as String,
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      date: DateTime.parse(map['date'] as String),
      type: LiquidityCheckpointType.values.byName(map['type'] as String),
      amount: (map['amount'] as num).toInt(),
      morningCheckpoint: (map['morningCheckpoint'] as num?)?.toInt(),
      eveningCheckpoint: (map['eveningCheckpoint'] as num?)?.toInt(),
      cashAmount: (map['cashAmount'] as num?)?.toInt(),
      simAmount: (map['simAmount'] as num?)?.toInt(),
      morningCashAmount: (map['morningCashAmount'] as num?)?.toInt(),
      morningSimAmount: (map['morningSimAmount'] as num?)?.toInt(),
      eveningCashAmount: (map['eveningCashAmount'] as num?)?.toInt(),
      eveningSimAmount: (map['eveningSimAmount'] as num?)?.toInt(),
      notes: map['notes'] as String?,
      deletedAt: map['deletedAt'] != null
          ? DateTime.parse(map['deletedAt'] as String)
          : null,
      deletedBy: map['deletedBy'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'date': date.toIso8601String(),
      'type': type.name,
      'amount': amount,
      'morningCheckpoint': morningCheckpoint,
      'eveningCheckpoint': eveningCheckpoint,
      'cashAmount': cashAmount,
      'simAmount': simAmount,
      'morningCashAmount': morningCashAmount,
      'morningSimAmount': morningSimAmount,
      'eveningCashAmount': eveningCashAmount,
      'eveningSimAmount': eveningSimAmount,
      'notes': notes,
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

/// Type de pointage de liquidité.
enum LiquidityCheckpointType {
  morning('Matin'),
  evening('Soir'),
  full('Complet');

  const LiquidityCheckpointType(this.label);
  final String label;
}
