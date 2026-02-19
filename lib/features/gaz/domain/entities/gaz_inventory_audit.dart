import 'cylinder.dart';

class GazInventoryAudit {
  const GazInventoryAudit({
    required this.id,
    required this.enterpriseId,
    required this.auditDate,
    required this.auditedBy,
    this.siteId,
    required this.items,
    this.notes,
    this.status = InventoryAuditStatus.draft,
  });

  final String id;
  final String enterpriseId;
  final DateTime auditDate;
  final String auditedBy;
  final String? siteId;
  final List<InventoryAuditItem> items;
  final String? notes;
  final InventoryAuditStatus status;

  factory GazInventoryAudit.fromMap(Map<String, dynamic> map) {
    return GazInventoryAudit(
      id: map['id'] as String,
      enterpriseId: map['enterpriseId'] as String,
      auditDate: DateTime.parse(map['auditDate'] as String),
      auditedBy: map['auditedBy'] as String,
      siteId: map['siteId'] as String?,
      items: (map['items'] as List<dynamic>)
          .map((i) => InventoryAuditItem.fromMap(i as Map<String, dynamic>))
          .toList(),
      notes: map['notes'] as String?,
      status: InventoryAuditStatus.values.byName(map['status'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'auditDate': auditDate.toIso8601String(),
      'auditedBy': auditedBy,
      'siteId': siteId,
      'items': items.map((i) => i.toMap()).toList(),
      'notes': notes,
      'status': status.name,
    };
  }
}

class InventoryAuditItem {
  const InventoryAuditItem({
    required this.stockId,
    required this.cylinderId,
    required this.weight,
    required this.status,
    required this.theoreticalQuantity,
    required this.physicalQuantity,
  });

  final String stockId;
  final String cylinderId;
  final int weight;
  final CylinderStatus status;
  final int theoreticalQuantity;
  final int physicalQuantity;

  int get discrepancy => physicalQuantity - theoreticalQuantity;

  factory InventoryAuditItem.fromMap(Map<String, dynamic> map) {
    return InventoryAuditItem(
      stockId: map['stockId'] as String,
      cylinderId: map['cylinderId'] as String,
      weight: map['weight'] as int,
      status: CylinderStatus.values.byName(map['status'] as String),
      theoreticalQuantity: map['theoreticalQuantity'] as int,
      physicalQuantity: map['physicalQuantity'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stockId': stockId,
      'cylinderId': cylinderId,
      'weight': weight,
      'status': status.name,
      'theoreticalQuantity': theoreticalQuantity,
      'physicalQuantity': physicalQuantity,
    };
  }
}

enum InventoryAuditStatus {
  draft,
  completed,
  cancelled,
}
