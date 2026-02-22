import 'dart:typed_data';

import 'production_payment_person.dart';

/// Represents a production payment record for weekly workers.
class ProductionPayment {
  const ProductionPayment({
    required this.id,
    required this.period,
    required this.paymentDate,
    required this.persons,
    this.notes,
    this.sourceProductionDayIds = const [],
    this.isVerified = false,
    this.verifiedBy,
    this.verifiedAt,
    this.signature,
    this.signerName, // Nom du signataire
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.deletedBy,
  });

  final String id;
  final String period; // e.g., "11-20 novembre 2025"
  final DateTime paymentDate;
  final List<ProductionPaymentPerson> persons;
  final String? notes;

  /// IDs des jours de production sources (traçabilité).
  final List<String> sourceProductionDayIds;

  /// Indique si le paiement a été vérifié et validé.
  final bool isVerified;

  /// ID de la personne qui a vérifié le paiement.
  final String? verifiedBy;

  /// Date de vérification du paiement.
  final DateTime? verifiedAt;

  /// Signature numérique du bénéficiaire (ou du représentant).
  final Uint8List? signature;

  /// Nom du signataire (optionnel).
  final String? signerName;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String? deletedBy;

  int get totalAmount =>
      persons.fold(0, (sum, p) => sum + p.effectiveTotalAmount);
  int get uniquePersonsCount => persons.length;

  ProductionPayment copyWith({
    String? id,
    String? period,
    DateTime? paymentDate,
    List<ProductionPaymentPerson>? persons,
    String? notes,
    List<String>? sourceProductionDayIds,
    bool? isVerified,
    String? verifiedBy,
    DateTime? verifiedAt,
    Uint8List? signature,
    String? signerName,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return ProductionPayment(
      id: id ?? this.id,
      period: period ?? this.period,
      paymentDate: paymentDate ?? this.paymentDate,
      persons: persons ?? this.persons,
      notes: notes ?? this.notes,
      sourceProductionDayIds:
          sourceProductionDayIds ?? this.sourceProductionDayIds,
      isVerified: isVerified ?? this.isVerified,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      signature: signature ?? this.signature,
      signerName: signerName ?? this.signerName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  factory ProductionPayment.fromMap(Map<String, dynamic> map) {
    final personsRaw = map['persons'] as List<dynamic>? ?? [];
    return ProductionPayment(
      id: map['id'] as String? ?? map['localId'] as String,
      period: map['period'] as String? ?? '',
      paymentDate: DateTime.parse(map['paymentDate'] as String),
      persons: personsRaw
          .map((p) => ProductionPaymentPerson.fromMap(p as Map<String, dynamic>))
          .toList(),
      notes: map['notes'] as String?,
      sourceProductionDayIds:
          (map['sourceProductionDayIds'] as List<dynamic>?)?.cast<String>() ??
              [],
      isVerified: map['isVerified'] as bool? ?? false,
      verifiedBy: map['verifiedBy'] as String?,
      verifiedAt: map['verifiedAt'] != null
          ? DateTime.parse(map['verifiedAt'] as String)
          : null,
      signature: map['signature'] != null
          ? Uint8List.fromList((map['signature'] as List<dynamic>).cast<int>())
          : null,
      signerName: map['signerName'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      deletedAt: map['deletedAt'] != null
          ? DateTime.parse(map['deletedAt'] as String)
          : null,
      deletedBy: map['deletedBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'period': period,
      'paymentDate': paymentDate.toIso8601String(),
      'persons': persons.map((p) => p.toMap()).toList(),
      'notes': notes,
      'sourceProductionDayIds': sourceProductionDayIds,
      'isVerified': isVerified,
      'verifiedBy': verifiedBy,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'signature': signature?.toList(),
      'signerName': signerName,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
    };
  }

  bool get isDeleted => deletedAt != null;
}
