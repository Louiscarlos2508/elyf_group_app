import '../../../administration/domain/entities/enterprise.dart';

/// Extensions pour faciliter l'utilisation de Enterprise comme Agent Orange Money
/// 
/// Au lieu d'avoir une entité Agent séparée, on utilise Enterprise avec metadata
/// pour stocker les informations spécifiques Orange Money.
extension OrangeMoneyEnterpriseExtension on Enterprise {
  /// Numéro d'agent officiel Orange Money
  String? get agentNumber => metadata['agentNumber'] as String?;

  /// Numéro SIM Orange Money
  String? get simNumber => metadata['simNumber'] as String?;

  /// Opérateur mobile (orange, mtn, moov, other)
  String? get operator => metadata['operator'] as String?;

  /// Taux de commission en pourcentage (ex: 2.5 pour 2.5%)
  double? get commissionRate {
    final rate = metadata['commissionRate'];
    if (rate == null) return null;
    if (rate is double) return rate;
    if (rate is int) return rate.toDouble();
    if (rate is String) return double.tryParse(rate);
    return null;
  }

  /// Liquidité totale disponible en FCFA
  int? get floatBalance {
    final balance = metadata['floatBalance'];
    if (balance == null) return null;
    if (balance is int) return balance;
    if (balance is double) return balance.toInt();
    if (balance is String) return int.tryParse(balance);
    return null;
  }

  /// Dette de liquidité (OM pris avant paiement cash)
  int? get floatDebt {
    final debt = metadata['floatDebt'];
    if (debt == null) return null;
    if (debt is int) return debt;
    if (debt is double) return debt.toInt();
    if (debt is String) return int.tryParse(debt);
    return null;
  }

  /// Opérateur principal (si multi-opérateur)
  String? get operatorName => metadata['operatorName'] as String?;

  /// Seuil critique de liquidité en FCFA
  int? get criticalThreshold {
    final threshold = metadata['criticalThreshold'];
    if (threshold == null) return 50000; // Valeur par défaut
    if (threshold is int) return threshold;
    if (threshold is double) return threshold.toInt();
    if (threshold is String) return int.tryParse(threshold);
    return 50000;
  }

  /// Zone géographique
  String? get zone => metadata['zone'] as String?;

  /// Manager/Gérant (pour kiosques)
  String? get manager => metadata['manager'] as String?;

  /// Horaires d'ouverture (pour kiosques)
  String? get openingHours => metadata['openingHours'] as String?;

  /// Vérifier si la liquidité est faible
  bool isLowLiquidity() {
    final balance = floatBalance;
    final threshold = criticalThreshold;
    if (balance == null || threshold == null) return false;
    return balance < threshold;
  }

  /// Créer une copie avec des métadonnées Orange Money mises à jour
  Enterprise copyWithOrangeMoneyMetadata({
    String? agentNumber,
    String? simNumber,
    String? operator,
    String? operatorName,
    double? commissionRate,
    int? floatBalance,
    int? floatDebt,
    int? criticalThreshold,
    String? zone,
    String? manager,
    String? openingHours,
  }) {
    final newMetadata = Map<String, dynamic>.from(metadata);

    if (agentNumber != null) newMetadata['agentNumber'] = agentNumber;
    if (simNumber != null) newMetadata['simNumber'] = simNumber;
    if (operator != null) newMetadata['operator'] = operator;
    if (operatorName != null) newMetadata['operatorName'] = operatorName;
    if (commissionRate != null) newMetadata['commissionRate'] = commissionRate;
    if (floatBalance != null) newMetadata['floatBalance'] = floatBalance;
    if (floatDebt != null) newMetadata['floatDebt'] = floatDebt;
    if (criticalThreshold != null) {
      newMetadata['criticalThreshold'] = criticalThreshold;
    }
    if (zone != null) newMetadata['zone'] = zone;
    if (manager != null) newMetadata['manager'] = manager;
    if (openingHours != null) newMetadata['openingHours'] = openingHours;

    return copyWith(metadata: newMetadata);
  }
}

/// Helper pour créer une Enterprise Orange Money
class OrangeMoneyEnterpriseHelper {
  /// Créer un agent principal Orange Money
  static Enterprise createAgent({
    required String id,
    required String name,
    required String agentNumber,
    required String simNumber,
    String operator = 'orange',
    double commissionRate = 2.5,
    int floatBalance = 0,
    int criticalThreshold = 50000,
    String? zone,
    String? phone,
    String? email,
    String? address,
    double? latitude,
    double? longitude,
  }) {
    return Enterprise(
      id: id,
      name: name,
      type: EnterpriseType.mobileMoneyAgent,
      moduleId: 'orange_money',
      phone: phone,
      email: email,
      address: address,
      latitude: latitude,
      longitude: longitude,
      metadata: {
        'agentNumber': agentNumber,
        'simNumber': simNumber,
        'operator': operator,
        'commissionRate': commissionRate,
        'floatBalance': floatBalance,
        'criticalThreshold': criticalThreshold,
        if (zone != null) 'zone': zone,
      },
      isActive: true,
      createdAt: DateTime.now(),
    );
  }

  /// Créer un kiosque (sous-agence)
  static Enterprise createKiosk({
    required String id,
    required String name,
    required String parentEnterpriseId,
    required int hierarchyLevel,
    required List<String> ancestorIds,
    String? manager,
    String? openingHours,
    int floatBalance = 0,
    int criticalThreshold = 50000,
    String? phone,
    String? address,
    double? latitude,
    double? longitude,
  }) {
    return Enterprise(
      id: id,
      name: name,
      type: EnterpriseType.mobileMoneyKiosk,
      parentEnterpriseId: parentEnterpriseId,
      hierarchyLevel: hierarchyLevel,
      ancestorIds: ancestorIds,
      moduleId: 'orange_money',
      phone: phone,
      address: address,
      latitude: latitude,
      longitude: longitude,
      metadata: {
        'floatBalance': floatBalance,
        'criticalThreshold': criticalThreshold,
        if (manager != null) 'manager': manager,
        if (openingHours != null) 'openingHours': openingHours,
      },
      isActive: true,
      createdAt: DateTime.now(),
    );
  }

  /// Créer un sous-agent
  static Enterprise createSubAgent({
    required String id,
    required String name,
    required String parentEnterpriseId,
    required int hierarchyLevel,
    required List<String> ancestorIds,
    String? agentNumber,
    String? simNumber,
    String operator = 'orange',
    double commissionRate = 2.5,
    int floatBalance = 0,
    int criticalThreshold = 50000,
    String? zone,
    String? phone,
    String? address,
    double? latitude,
    double? longitude,
  }) {
    return Enterprise(
      id: id,
      name: name,
      type: EnterpriseType.mobileMoneySubAgent,
      parentEnterpriseId: parentEnterpriseId,
      hierarchyLevel: hierarchyLevel,
      ancestorIds: ancestorIds,
      moduleId: 'orange_money',
      phone: phone,
      address: address,
      latitude: latitude,
      longitude: longitude,
      metadata: {
        if (agentNumber != null) 'agentNumber': agentNumber,
        if (simNumber != null) 'simNumber': simNumber,
        'operator': operator,
        'commissionRate': commissionRate,
        'floatBalance': floatBalance,
        'criticalThreshold': criticalThreshold,
        if (zone != null) 'zone': zone,
      },
      isActive: true,
      createdAt: DateTime.now(),
    );
  }

  /// Créer un distributeur
  static Enterprise createDistributor({
    required String id,
    required String name,
    required String parentEnterpriseId,
    required int hierarchyLevel,
    required List<String> ancestorIds,
    int floatBalance = 0,
    String? phone,
    String? address,
    double? latitude,
    double? longitude,
  }) {
    return Enterprise(
      id: id,
      name: name,
      type: EnterpriseType.mobileMoneyDistributor,
      parentEnterpriseId: parentEnterpriseId,
      hierarchyLevel: hierarchyLevel,
      ancestorIds: ancestorIds,
      moduleId: 'orange_money',
      phone: phone,
      address: address,
      latitude: latitude,
      longitude: longitude,
      metadata: {
        'floatBalance': floatBalance,
      },
      isActive: true,
      createdAt: DateTime.now(),
    );
  }
}
