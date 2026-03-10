/// Représente un record de réconciliation logistique pour un point de vente.
class GazSiteLogisticsRecord {
  const GazSiteLogisticsRecord({
    required this.id,
    required this.enterpriseId,
    required this.siteId,
    this.totalConsignedValue = 0.0,
    this.totalRemittedValue = 0.0,
    this.totalLeakValue = 0.0,
    required this.updatedAt,
  });

  final String id;
  final String enterpriseId;
  final String siteId;
  final double totalConsignedValue;
  final double totalRemittedValue;
  final double totalLeakValue;
  final DateTime updatedAt;

  double get currentBalance => totalConsignedValue - totalRemittedValue - totalLeakValue;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'localId': id,
      'enterpriseId': enterpriseId,
      'siteId': siteId,
      'totalConsignedValue': totalConsignedValue,
      'totalRemittedValue': totalRemittedValue,
      'totalLeakValue': totalLeakValue,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory GazSiteLogisticsRecord.fromMap(Map<String, dynamic> map) {
    return GazSiteLogisticsRecord(
      id: map['id'] as String? ?? '',
      enterpriseId: map['enterpriseId'] as String? ?? '',
      siteId: map['siteId'] as String? ?? '',
      totalConsignedValue: (map['totalConsignedValue'] as num?)?.toDouble() ?? 0.0,
      totalRemittedValue: (map['totalRemittedValue'] as num?)?.toDouble() ?? 0.0,
      totalLeakValue: (map['totalLeakValue'] as num?)?.toDouble() ?? 0.0,
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt'] as String) 
          : DateTime.now(),
    );
  }

  GazSiteLogisticsRecord copyWith({
    String? id,
    String? enterpriseId,
    String? siteId,
    double? totalConsignedValue,
    double? totalRemittedValue,
    double? totalLeakValue,
    DateTime? updatedAt,
  }) {
    return GazSiteLogisticsRecord(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      siteId: siteId ?? this.siteId,
      totalConsignedValue: totalConsignedValue ?? this.totalConsignedValue,
      totalRemittedValue: totalRemittedValue ?? this.totalRemittedValue,
      totalLeakValue: totalLeakValue ?? this.totalLeakValue,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
