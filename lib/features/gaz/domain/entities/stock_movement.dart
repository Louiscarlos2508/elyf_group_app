import 'cylinder.dart';

enum StockMovementType {
  sale('Vente'),
  replenishment('Approvisionnement'),
  leak('Fuite'),
  defective('Défectueux'),
  exchange('Échange'),
  adjustment('Ajustement');

  const StockMovementType(this.label);
  final String label;
}

class StockMovement {
  const StockMovement({
    required this.id,
    required this.enterpriseId,
    required this.timestamp,
    required this.type,
    required this.cylinderId,
    required this.weight,
    required this.status,
    required this.quantityDelta,
    this.siteId,
    this.userId,
    this.referenceId, // e.g. saleId, tourId, leakId
    this.notes,
  });

  final String id;
  final String enterpriseId;
  final DateTime timestamp;
  final StockMovementType type;
  final String cylinderId;
  final int weight;
  final CylinderStatus status;
  final int quantityDelta; // Positive for increase, negative for decrease
  final String? siteId;
  final String? userId;
  final String? referenceId;
  final String? notes;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'cylinderId': cylinderId,
      'weight': weight,
      'status': status.name,
      'quantityDelta': quantityDelta,
      'siteId': siteId,
      'userId': userId,
      'referenceId': referenceId,
      'notes': notes,
    };
  }

  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: map['id'] as String,
      enterpriseId: map['enterpriseId'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      type: StockMovementType.values.byName(map['type'] as String),
      cylinderId: map['cylinderId'] as String,
      weight: map['weight'] as int,
      status: CylinderStatus.values.byName(map['status'] as String),
      quantityDelta: map['quantityDelta'] as int,
      siteId: map['siteId'] as String?,
      userId: map['userId'] as String?,
      referenceId: map['referenceId'] as String?,
      notes: map['notes'] as String?,
    );
  }
}
