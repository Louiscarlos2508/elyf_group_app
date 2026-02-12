import 'cylinder.dart';

/// Représente le stock d'une bouteille avec un statut donné.
class CylinderStock {
  const CylinderStock({
    required this.id,
    required this.cylinderId,
    required this.weight,
    required this.status,
    required this.quantity,
    required this.enterpriseId,
    required this.updatedAt,
    this.siteId,
    this.createdAt,
    this.deletedAt,
    this.deletedBy,
  });

  final String id;
  final String cylinderId;
  final int weight; // 3, 6, 10, 12
  final CylinderStatus status;
  final int quantity;
  final String enterpriseId;
  final String? siteId; // Pour sites distants (ex: Bogandé)
  final DateTime updatedAt;
  final DateTime? createdAt;
  final DateTime? deletedAt;
  final String? deletedBy;

  CylinderStock copyWith({
    String? id,
    String? cylinderId,
    int? weight,
    CylinderStatus? status,
    int? quantity,
    String? enterpriseId,
    String? siteId,
    DateTime? updatedAt,
    DateTime? createdAt,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return CylinderStock(
      id: id ?? this.id,
      cylinderId: cylinderId ?? this.cylinderId,
      weight: weight ?? this.weight,
      status: status ?? this.status,
      quantity: quantity ?? this.quantity,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      siteId: siteId ?? this.siteId,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  factory CylinderStock.fromMap(Map<String, dynamic> map, String defaultEnterpriseId) {
    return CylinderStock(
      id: map['id'] as String? ?? map['localId'] as String,
      cylinderId: map['cylinderId'] as String? ?? '',
      weight: (map['weight'] as num?)?.toInt() ?? 0,
      status: CylinderStatus.values.byName(map['status'] as String? ?? 'full'),
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      siteId: map['siteId'] as String?,
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
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
      'cylinderId': cylinderId,
      'weight': weight,
      'status': status.name,
      'quantity': quantity,
      'enterpriseId': enterpriseId,
      'siteId': siteId,
      'updatedAt': updatedAt.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
    };
  }

  bool get isDeleted => deletedAt != null;
}
