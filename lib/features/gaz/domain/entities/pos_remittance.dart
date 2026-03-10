import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';

/// Statut d'un versement.
enum RemittanceStatus {
  pending('En attente'),
  validated('Validé'),
  rejected('Rejeté');

  const RemittanceStatus(this.label);
  final String label;
}

/// Représente un versement de fonds d'un POS vers l'entreprise mère.
class GazPOSRemittance {
  const GazPOSRemittance({
    required this.id,
    required this.enterpriseId,
    required this.posId,
    required this.amount,
    required this.remittanceDate,
    this.status = RemittanceStatus.pending,
    this.paymentMethod = PaymentMethod.cash,
    this.reference,
    this.notes,
    this.tourId,
    this.validatedBy,
    this.validatedAt,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String enterpriseId; // ID de l'entreprise mère
  final String posId; // ID du point de vente
  final double amount;
  final DateTime remittanceDate;
  final RemittanceStatus status;
  final PaymentMethod paymentMethod;
  final String? reference; // Référence de transaction (OM/Momo/Bancaire)
  final String? notes;
  final String? tourId;
  final String? validatedBy;
  final DateTime? validatedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  factory GazPOSRemittance.fromMap(Map<String, dynamic> map, String defaultEnterpriseId) {
    final validLocalId = map['localId'] as String?;
    final objectId = (validLocalId != null && validLocalId.trim().isNotEmpty)
        ? validLocalId
        : (map['id'] as String? ?? '');

    return GazPOSRemittance(
      id: objectId,
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      posId: map['posId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      remittanceDate: map['remittanceDate'] != null
          ? DateTime.parse(map['remittanceDate'] as String)
          : DateTime.now(),
      status: RemittanceStatus.values.byName(map['status'] as String? ?? 'pending'),
      paymentMethod: map['paymentMethod'] != null
          ? PaymentMethod.values.byName(map['paymentMethod'] as String)
          : PaymentMethod.cash,
      reference: map['reference'] as String?,
      notes: map['notes'] as String?,
      tourId: map['tourId'] as String?,
      validatedBy: map['validatedBy'] as String?,
      validatedAt: map['validatedAt'] != null ? DateTime.parse(map['validatedAt'] as String) : null,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : null,
      deletedAt: map['deletedAt'] != null ? DateTime.parse(map['deletedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'localId': id,
      'enterpriseId': enterpriseId,
      'posId': posId,
      'amount': amount,
      'remittanceDate': remittanceDate.toIso8601String(),
      'status': status.name,
      'paymentMethod': paymentMethod.name,
      'reference': reference,
      'notes': notes,
      'tourId': tourId,
      'validatedBy': validatedBy,
      'validatedAt': validatedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  GazPOSRemittance copyWith({
    String? id,
    String? enterpriseId,
    String? posId,
    double? amount,
    DateTime? remittanceDate,
    RemittanceStatus? status,
    PaymentMethod? paymentMethod,
    String? reference,
    String? notes,
    String? tourId,
    String? validatedBy,
    DateTime? validatedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return GazPOSRemittance(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      posId: posId ?? this.posId,
      amount: amount ?? this.amount,
      remittanceDate: remittanceDate ?? this.remittanceDate,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      reference: reference ?? this.reference,
      notes: notes ?? this.notes,
      tourId: tourId ?? this.tourId,
      validatedBy: validatedBy ?? this.validatedBy,
      validatedAt: validatedAt ?? this.validatedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  bool get isValidated => status == RemittanceStatus.validated;
}
