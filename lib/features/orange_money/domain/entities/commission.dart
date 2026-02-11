/// Represents a commission period and calculation.
class Commission {
  const Commission({
    required this.id,
    required this.period,
    required this.amount,
    required this.status,
    required this.transactionsCount,
    required this.estimatedAmount,
    required this.enterpriseId,
    this.photoUrl,
    this.paidAt,
    this.paymentDueDate,
    this.notes,
    this.deletedAt,
    this.deletedBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String period; // Format: "YYYY-MM" (ex: "2025-12")
  final int amount; // Montant de la commission en FCFA
  final CommissionStatus status;
  final int transactionsCount; // Nombre de transactions validées
  final int estimatedAmount; // Montant estimé en FCFA (pour le mois en cours)
  final String enterpriseId;
  final String? photoUrl; // URL de la photo de preuve (Firebase Storage)
  final DateTime? paidAt;
  final DateTime? paymentDueDate;
  final String? notes;
  final DateTime? deletedAt;
  final String? deletedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isDeleted => deletedAt != null;

  /// Vérifie si la commission est payée.
  bool get isPaid => status == CommissionStatus.paid;

  /// Vérifie si la commission est en attente.
  bool get isPending => status == CommissionStatus.pending;

  /// Vérifie si la commission est en cours de calcul (mois actuel).
  bool get isEstimated => status == CommissionStatus.estimated;

  /// Vérifie si le paiement est proche de l'échéance.
  bool isPaymentDueSoon(int daysBefore) {
    if (paymentDueDate == null) return false;
    final now = DateTime.now();
    final difference = paymentDueDate!.difference(now).inDays;
    return difference <= daysBefore && difference >= 0;
  }

  Commission copyWith({
    String? id,
    String? period,
    int? amount,
    CommissionStatus? status,
    int? transactionsCount,
    int? estimatedAmount,
    String? enterpriseId,
    String? photoUrl,
    DateTime? paidAt,
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
      amount: amount ?? this.amount,
      status: status ?? this.status,
      transactionsCount: transactionsCount ?? this.transactionsCount,
      estimatedAmount: estimatedAmount ?? this.estimatedAmount,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      photoUrl: photoUrl ?? this.photoUrl,
      paidAt: paidAt ?? this.paidAt,
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
      amount: (map['amount'] as num).toInt(),
      status: CommissionStatus.values.byName(map['status'] as String),
      transactionsCount: (map['transactionsCount'] as num).toInt(),
      estimatedAmount: (map['estimatedAmount'] as num).toInt(),
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      photoUrl: map['photoUrl'] as String?,
      paidAt: map['paidAt'] != null ? DateTime.parse(map['paidAt'] as String) : null,
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
      'amount': amount,
      'status': status.name,
      'transactionsCount': transactionsCount,
      'estimatedAmount': estimatedAmount,
      'enterpriseId': enterpriseId,
      'photoUrl': photoUrl,
      'paidAt': paidAt?.toIso8601String(),
      'paymentDueDate': paymentDueDate?.toIso8601String(),
      'notes': notes,
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

enum CommissionStatus {
  estimated, // Estimée pour le mois en cours (non calculée)
  pending, // Calculée mais pas encore payée
  paid, // Payée
}

extension CommissionStatusExtension on CommissionStatus {
  String get label {
    switch (this) {
      case CommissionStatus.estimated:
        return 'Estimée';
      case CommissionStatus.pending:
        return 'En attente';
      case CommissionStatus.paid:
        return 'Payée';
    }
  }
}
