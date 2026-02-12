/// Represents a commission period with hybrid calculation model.
/// 
/// Supports both estimated calculation (system) and declared amount (SMS operator).
class Commission {
  const Commission({
    required this.id,
    required this.period,
    required this.enterpriseId,
    required this.estimatedAmount,
    required this.transactionsCount,
    this.calculationDetails,
    this.declaredAmount,
    this.smsProofUrl,
    this.declaredAt,
    this.declaredBy,
    this.discrepancy,
    this.discrepancyPercentage,
    this.discrepancyStatus,
    required this.status,
    this.validatedAt,
    this.validatedBy,
    this.paidAt,
    this.paymentProofUrl,
    this.paymentDueDate,
    this.notes,
    this.deletedAt,
    this.deletedBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String period; // Format: "YYYY-MM" (ex: "2026-01")
  final String enterpriseId;

  // CALCUL ESTIMATIF (Système)
  final int estimatedAmount; // Montant calculé par le système (FCFA)
  final int transactionsCount; // Nombre de transactions
  final CommissionCalculationDetails? calculationDetails; // Détails du calcul

  // DÉCLARATION RÉELLE (Agent via SMS Opérateur)
  final int? declaredAmount; // Montant du SMS opérateur (FCFA)
  final String? smsProofUrl; // URL screenshot SMS (Firebase Storage)
  final DateTime? declaredAt; // Date de déclaration
  final String? declaredBy; // Utilisateur qui a déclaré

  // RAPPROCHEMENT
  final int? discrepancy; // Écart = declaredAmount - estimatedAmount
  final double? discrepancyPercentage; // Écart en %
  final DiscrepancyStatus? discrepancyStatus; // Statut de l'écart

  // VALIDATION & PAIEMENT
  final CommissionStatus status;
  final DateTime? validatedAt; // Date de validation entreprise
  final String? validatedBy; // Qui a validé
  final DateTime? paidAt; // Date de paiement
  final String? paymentProofUrl; // Preuve de paiement
  final DateTime? paymentDueDate; // Date d'échéance de paiement
  final String? notes;

  // SOFT DELETE
  final DateTime? deletedAt;
  final String? deletedBy;

  // TIMESTAMPS
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isDeleted => deletedAt != null;

  /// Vérifie si la commission est payée
  bool get isPaid => status == CommissionStatus.paid;

  /// Vérifie si la commission est validée
  bool get isValidated => status == CommissionStatus.validated;

  /// Vérifie si la commission est déclarée
  bool get isDeclared => status == CommissionStatus.declared;

  /// Vérifie si la commission est estimée (mois en cours)
  bool get isEstimated => status == CommissionStatus.estimated;

  /// Vérifie si la commission est en litige
  bool get isDisputed => status == CommissionStatus.disputed;

  /// Vérifie si le paiement est proche de l'échéance
  bool isPaymentDueSoon(int daysBefore) {
    if (paymentDueDate == null) return false;
    final now = DateTime.now();
    final difference = paymentDueDate!.difference(now).inDays;
    return difference <= daysBefore && difference >= 0;
  }

  /// Montant final (déclaré si disponible, sinon estimé)
  int get finalAmount => declaredAmount ?? estimatedAmount;

  Commission copyWith({
    String? id,
    String? period,
    String? enterpriseId,
    int? estimatedAmount,
    int? transactionsCount,
    CommissionCalculationDetails? calculationDetails,
    int? declaredAmount,
    String? smsProofUrl,
    DateTime? declaredAt,
    String? declaredBy,
    int? discrepancy,
    double? discrepancyPercentage,
    DiscrepancyStatus? discrepancyStatus,
    CommissionStatus? status,
    DateTime? validatedAt,
    String? validatedBy,
    DateTime? paidAt,
    String? paymentProofUrl,
    DateTime? paymentDueDate,
    String? notes,
    DateTime? deletedAt,
    String? deletedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Commission(
      id: id ?? this.id,
      period: period ?? this.period,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      estimatedAmount: estimatedAmount ?? this.estimatedAmount,
      transactionsCount: transactionsCount ?? this.transactionsCount,
      calculationDetails: calculationDetails ?? this.calculationDetails,
      declaredAmount: declaredAmount ?? this.declaredAmount,
      smsProofUrl: smsProofUrl ?? this.smsProofUrl,
      declaredAt: declaredAt ?? this.declaredAt,
      declaredBy: declaredBy ?? this.declaredBy,
      discrepancy: discrepancy ?? this.discrepancy,
      discrepancyPercentage: discrepancyPercentage ?? this.discrepancyPercentage,
      discrepancyStatus: discrepancyStatus ?? this.discrepancyStatus,
      status: status ?? this.status,
      validatedAt: validatedAt ?? this.validatedAt,
      validatedBy: validatedBy ?? this.validatedBy,
      paidAt: paidAt ?? this.paidAt,
      paymentProofUrl: paymentProofUrl ?? this.paymentProofUrl,
      paymentDueDate: paymentDueDate ?? this.paymentDueDate,
      notes: notes ?? this.notes,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Commission.fromMap(
    Map<String, dynamic> map,
    String defaultEnterpriseId,
  ) {
    return Commission(
      id: map['id'] as String? ?? map['localId'] as String,
      period: map['period'] as String,
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      estimatedAmount: (map['estimatedAmount'] as num).toInt(),
      transactionsCount: (map['transactionsCount'] as num).toInt(),
      calculationDetails: map['calculationDetails'] != null
          ? CommissionCalculationDetails.fromMap(
              map['calculationDetails'] as Map<String, dynamic>,
            )
          : null,
      declaredAmount: map['declaredAmount'] != null
          ? (map['declaredAmount'] as num).toInt()
          : null,
      smsProofUrl: map['smsProofUrl'] as String?,
      declaredAt: map['declaredAt'] != null
          ? DateTime.parse(map['declaredAt'] as String)
          : null,
      declaredBy: map['declaredBy'] as String?,
      discrepancy: map['discrepancy'] != null
          ? (map['discrepancy'] as num).toInt()
          : null,
      discrepancyPercentage: map['discrepancyPercentage'] != null
          ? (map['discrepancyPercentage'] as num).toDouble()
          : null,
      discrepancyStatus: map['discrepancyStatus'] != null
          ? DiscrepancyStatus.values.byName(map['discrepancyStatus'] as String)
          : null,
      status: CommissionStatus.values.byName(map['status'] as String),
      validatedAt: map['validatedAt'] != null
          ? DateTime.parse(map['validatedAt'] as String)
          : null,
      validatedBy: map['validatedBy'] as String?,
      paidAt:
          map['paidAt'] != null ? DateTime.parse(map['paidAt'] as String) : null,
      paymentProofUrl: map['paymentProofUrl'] as String?,
      paymentDueDate: map['paymentDueDate'] != null
          ? DateTime.parse(map['paymentDueDate'] as String)
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
      'period': period,
      'enterpriseId': enterpriseId,
      'estimatedAmount': estimatedAmount,
      'transactionsCount': transactionsCount,
      'calculationDetails': calculationDetails?.toMap(),
      'declaredAmount': declaredAmount,
      'smsProofUrl': smsProofUrl,
      'declaredAt': declaredAt?.toIso8601String(),
      'declaredBy': declaredBy,
      'discrepancy': discrepancy,
      'discrepancyPercentage': discrepancyPercentage,
      'discrepancyStatus': discrepancyStatus?.name,
      'status': status.name,
      'validatedAt': validatedAt?.toIso8601String(),
      'validatedBy': validatedBy,
      'paidAt': paidAt?.toIso8601String(),
      'paymentProofUrl': paymentProofUrl,
      'paymentDueDate': paymentDueDate?.toIso8601String(),
      'notes': notes,
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

/// Détails du calcul de commission
class CommissionCalculationDetails {
  const CommissionCalculationDetails({
    required this.transactionsByTranche,
    required this.commissionsByTranche,
    required this.totalCashIn,
    required this.totalCashOut,
    required this.cashInCommission,
    required this.cashOutCommission,
  });

  final Map<String, int> transactionsByTranche; // {"0-5000": 10, "5001-25000": 25}
  final Map<String, int> commissionsByTranche; // {"0-5000": 0, "5001-25000": 2500}
  final int totalCashIn; // Volume total Cash-In (FCFA)
  final int totalCashOut; // Volume total Cash-Out (FCFA)
  final int cashInCommission; // Commission totale Cash-In (FCFA)
  final int cashOutCommission; // Commission totale Cash-Out (FCFA)

  factory CommissionCalculationDetails.fromMap(Map<String, dynamic> map) {
    return CommissionCalculationDetails(
      transactionsByTranche: Map<String, int>.from(
        map['transactionsByTranche'] as Map? ?? {},
      ),
      commissionsByTranche: Map<String, int>.from(
        map['commissionsByTranche'] as Map? ?? {},
      ),
      totalCashIn: (map['totalCashIn'] as num).toInt(),
      totalCashOut: (map['totalCashOut'] as num).toInt(),
      cashInCommission: (map['cashInCommission'] as num).toInt(),
      cashOutCommission: (map['cashOutCommission'] as num).toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'transactionsByTranche': transactionsByTranche,
      'commissionsByTranche': commissionsByTranche,
      'totalCashIn': totalCashIn,
      'totalCashOut': totalCashOut,
      'cashInCommission': cashInCommission,
      'cashOutCommission': cashOutCommission,
    };
  }
}

/// Statut de la commission
enum CommissionStatus {
  estimated, // Calculée automatiquement (mois en cours)
  declared, // Agent a déclaré le montant SMS
  validated, // Entreprise a validé
  paid, // Payée
  disputed, // Écart significatif en investigation
}

/// Statut de l'écart entre estimé et déclaré
enum DiscrepancyStatus {
  conforme, // Écart < 1%
  ecartMineur, // Écart 1-5%
  ecartSignificatif, // Écart > 5%
}

extension CommissionStatusExtension on CommissionStatus {
  String get label {
    switch (this) {
      case CommissionStatus.estimated:
        return 'Estimée';
      case CommissionStatus.declared:
        return 'Déclarée';
      case CommissionStatus.validated:
        return 'Validée';
      case CommissionStatus.paid:
        return 'Payée';
      case CommissionStatus.disputed:
        return 'En litige';
    }
  }

  String get description {
    switch (this) {
      case CommissionStatus.estimated:
        return 'Calculée automatiquement pour le mois en cours';
      case CommissionStatus.declared:
        return 'Montant SMS déclaré par l\'agent';
      case CommissionStatus.validated:
        return 'Validée par l\'entreprise';
      case CommissionStatus.paid:
        return 'Commission payée';
      case CommissionStatus.disputed:
        return 'Écart significatif en investigation';
    }
  }
}

extension DiscrepancyStatusExtension on DiscrepancyStatus {
  String get label {
    switch (this) {
      case DiscrepancyStatus.conforme:
        return 'Conforme';
      case DiscrepancyStatus.ecartMineur:
        return 'Écart Mineur';
      case DiscrepancyStatus.ecartSignificatif:
        return 'Écart Significatif';
    }
  }

  String get description {
    switch (this) {
      case DiscrepancyStatus.conforme:
        return 'Écart inférieur à 1%';
      case DiscrepancyStatus.ecartMineur:
        return 'Écart entre 1% et 5%';
      case DiscrepancyStatus.ecartSignificatif:
        return 'Écart supérieur à 5%';
    }
  }
}
