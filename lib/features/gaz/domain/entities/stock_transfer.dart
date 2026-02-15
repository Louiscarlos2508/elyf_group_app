import 'cylinder.dart';

enum StockTransferStatus {
  pending('En attente'),
  shipped('Expédié'),
  received('Reçu'),
  cancelled('Annulé');

  const StockTransferStatus(this.label);
  final String label;
}

class StockTransferItem {
  const StockTransferItem({
    required this.weight,
    required this.status,
    required this.quantity,
  });

  final int weight;
  final CylinderStatus status;
  final int quantity;

  Map<String, dynamic> toMap() {
    return {
      'weight': weight,
      'status': status.name,
      'quantity': quantity,
    };
  }

  factory StockTransferItem.fromMap(Map<String, dynamic> map) {
    return StockTransferItem(
      weight: map['weight'] as int,
      status: CylinderStatus.values.byName(map['status'] as String),
      quantity: map['quantity'] as int,
    );
  }
}

class StockTransfer {
  const StockTransfer({
    required this.id,
    required this.fromEnterpriseId,
    required this.toEnterpriseId,
    required this.items,
    required this.status,
    required this.createdBy,
    this.shippingDate,
    this.deliveryDate,
    this.driverId,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String fromEnterpriseId;
  final String toEnterpriseId;
  final List<StockTransferItem> items;
  final StockTransferStatus status;
  final String createdBy;
  final DateTime? shippingDate;
  final DateTime? deliveryDate;
  final String? driverId;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StockTransfer copyWith({
    String? id,
    String? fromEnterpriseId,
    String? toEnterpriseId,
    List<StockTransferItem>? items,
    StockTransferStatus? status,
    String? createdBy,
    DateTime? shippingDate,
    DateTime? deliveryDate,
    String? driverId,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StockTransfer(
      id: id ?? this.id,
      fromEnterpriseId: fromEnterpriseId ?? this.fromEnterpriseId,
      toEnterpriseId: toEnterpriseId ?? this.toEnterpriseId,
      items: items ?? this.items,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      shippingDate: shippingDate ?? this.shippingDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      driverId: driverId ?? this.driverId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fromEnterpriseId': fromEnterpriseId,
      'toEnterpriseId': toEnterpriseId,
      'items': items.map((i) => i.toMap()).toList(),
      'status': status.name,
      'createdBy': createdBy,
      'shippingDate': shippingDate?.toIso8601String(),
      'deliveryDate': deliveryDate?.toIso8601String(),
      'driverId': driverId,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory StockTransfer.fromMap(Map<String, dynamic> map) {
    return StockTransfer(
      id: map['id'] as String? ?? map['localId'] as String,
      fromEnterpriseId: map['fromEnterpriseId'] as String,
      toEnterpriseId: map['toEnterpriseId'] as String,
      items: (map['items'] as List<dynamic>)
          .map((i) => StockTransferItem.fromMap(i as Map<String, dynamic>))
          .toList(),
      status: StockTransferStatus.values.byName(map['status'] as String),
      createdBy: map['createdBy'] as String,
      shippingDate: map['shippingDate'] != null
          ? DateTime.parse(map['shippingDate'] as String)
          : null,
      deliveryDate: map['deliveryDate'] != null
          ? DateTime.parse(map['deliveryDate'] as String)
          : null,
      driverId: map['driverId'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }
}
