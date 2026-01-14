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
  });

  final String id;
  final String cylinderId;
  final int weight; // 3, 6, 10, 12
  final CylinderStatus status;
  final int quantity;
  final String enterpriseId;
  final String? siteId; // Pour sites distants (ex: Bogandé)
  final DateTime updatedAt;

  CylinderStock copyWith({
    String? id,
    String? cylinderId,
    int? weight,
    CylinderStatus? status,
    int? quantity,
    String? enterpriseId,
    String? siteId,
    DateTime? updatedAt,
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
    );
  }
}
