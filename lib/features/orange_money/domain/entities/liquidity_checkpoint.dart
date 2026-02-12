/// Represents a liquidity checkpoint (pointage de liquidité) with theoretical calculation.
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
    this.theoreticalCash, // Cash théorique calculé (FCFA)
    this.theoreticalSim, // SIM théorique calculé (FCFA)
    this.cashDiscrepancy, // Écart cash (réel - théorique)
    this.simDiscrepancy, // Écart SIM (réel - théorique)
    this.discrepancyPercentage, // Écart total en %
    this.requiresJustification = false, // Si écart > seuil
    this.justification, // Justification de l'écart
    this.validatedBy, // Qui a validé l'écart
    this.validatedAt, // Date de validation
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

  // CALCUL THÉORIQUE (pour pointage du soir)
  final int? theoreticalCash; // Cash théorique calculé
  final int? theoreticalSim; // SIM théorique calculé
  final int? cashDiscrepancy; // Écart cash (réel - théorique)
  final int? simDiscrepancy; // Écart SIM (réel - théorique)
  final double? discrepancyPercentage; // Écart en %

  // VALIDATION ÉCART
  final bool requiresJustification; // Si écart > seuil
  final String? justification; // Justification de l'écart
  final String? validatedBy; // Qui a validé l'écart
  final DateTime? validatedAt; // Date de validation

  final String? notes;
  final DateTime? deletedAt;
  final String? deletedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isDeleted => deletedAt != null;

  /// Vérifie si le pointage du matin est effectué
  bool get hasMorningCheckpoint =>
      (morningCashAmount != null && morningCashAmount! > 0) ||
      (morningSimAmount != null && morningSimAmount! > 0);

  /// Vérifie si le pointage du soir est effectué
  bool get hasEveningCheckpoint =>
      (eveningCashAmount != null && eveningCashAmount! > 0) ||
      (eveningSimAmount != null && eveningSimAmount! > 0);

  /// Vérifie si les deux pointages sont effectués
  bool get isComplete => hasMorningCheckpoint && hasEveningCheckpoint;

  /// Vérifie si l'écart est validé
  bool get isValidated => validatedAt != null;

  /// Écart total absolu
  int? get totalDiscrepancy {
    if (cashDiscrepancy == null || simDiscrepancy == null) return null;
    return cashDiscrepancy!.abs() + simDiscrepancy!.abs();
  }

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
    int? theoreticalCash,
    int? theoreticalSim,
    int? cashDiscrepancy,
    int? simDiscrepancy,
    double? discrepancyPercentage,
    bool? requiresJustification,
    String? justification,
    String? validatedBy,
    DateTime? validatedAt,
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
      theoreticalCash: theoreticalCash ?? this.theoreticalCash,
      theoreticalSim: theoreticalSim ?? this.theoreticalSim,
      cashDiscrepancy: cashDiscrepancy ?? this.cashDiscrepancy,
      simDiscrepancy: simDiscrepancy ?? this.simDiscrepancy,
      discrepancyPercentage:
          discrepancyPercentage ?? this.discrepancyPercentage,
      requiresJustification:
          requiresJustification ?? this.requiresJustification,
      justification: justification ?? this.justification,
      validatedBy: validatedBy ?? this.validatedBy,
      validatedAt: validatedAt ?? this.validatedAt,
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
      theoreticalCash: (map['theoreticalCash'] as num?)?.toInt(),
      theoreticalSim: (map['theoreticalSim'] as num?)?.toInt(),
      cashDiscrepancy: (map['cashDiscrepancy'] as num?)?.toInt(),
      simDiscrepancy: (map['simDiscrepancy'] as num?)?.toInt(),
      discrepancyPercentage:
          (map['discrepancyPercentage'] as num?)?.toDouble(),
      requiresJustification: map['requiresJustification'] as bool? ?? false,
      justification: map['justification'] as String?,
      validatedBy: map['validatedBy'] as String?,
      validatedAt: map['validatedAt'] != null
          ? DateTime.parse(map['validatedAt'] as String)
          : null,
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
      'theoreticalCash': theoreticalCash,
      'theoreticalSim': theoreticalSim,
      'cashDiscrepancy': cashDiscrepancy,
      'simDiscrepancy': simDiscrepancy,
      'discrepancyPercentage': discrepancyPercentage,
      'requiresJustification': requiresJustification,
      'justification': justification,
      'validatedBy': validatedBy,
      'validatedAt': validatedAt?.toIso8601String(),
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
