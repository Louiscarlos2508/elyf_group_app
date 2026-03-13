import 'electricity_meter_type.dart';

/// Configuration settings for the Eau Minérale module.
class EauMineraleSettings {
  const EauMineraleSettings({
    required this.id,
    required this.enterpriseId,
    this.meterType = ElectricityMeterType.classic,
    this.electricityRate = 125.0,
    this.updatedAt,
  });

  final String id;
  final String enterpriseId;
  final ElectricityMeterType meterType;
  final double electricityRate;
  final DateTime? updatedAt;

  EauMineraleSettings copyWith({
    String? id,
    String? enterpriseId,
    ElectricityMeterType? meterType,
    double? electricityRate,
    DateTime? updatedAt,
  }) {
    return EauMineraleSettings(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      meterType: meterType ?? this.meterType,
      electricityRate: electricityRate ?? this.electricityRate,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory EauMineraleSettings.fromMap(Map<String, dynamic> map, String id) {
    return EauMineraleSettings(
      id: id,
      enterpriseId: map['enterpriseId'] as String? ?? '',
      meterType: map['meterType'] != null
          ? ElectricityMeterType.values.byName(map['meterType'] as String)
          : ElectricityMeterType.classic,
      electricityRate: (map['electricityRate'] as num?)?.toDouble() ?? 125.0,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'meterType': meterType.name,
      'electricityRate': electricityRate,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Default settings for an enterprise.
  factory EauMineraleSettings.defaultSettings(String enterpriseId) {
    return EauMineraleSettings(
      id: 'default',
      enterpriseId: enterpriseId,
    );
  }
}
