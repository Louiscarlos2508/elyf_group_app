/// Represents an affiliated agent for Orange Money operations.
class Agent {
  const Agent({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.simNumber,
    required this.operator,
    required this.liquidity,
    required this.commissionRate,
    required this.status,
    required this.enterpriseId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String phoneNumber;
  final String simNumber;
  final MobileOperator operator;
  final int liquidity; // Liquidité disponible en FCFA
  final double commissionRate; // Taux de commission en pourcentage (ex: 2.5 pour 2.5%)
  final AgentStatus status;
  final String enterpriseId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Vérifie si l'agent est actif.
  bool get isActive => status == AgentStatus.active;

  /// Vérifie si l'agent a une liquidité faible (en dessous d'un seuil).
  bool isLowLiquidity(int threshold) => liquidity < threshold;
}

enum AgentStatus {
  active,
  inactive,
  suspended,
}

enum MobileOperator {
  orange,
  mtn,
  moov,
  other,
}

extension AgentStatusExtension on AgentStatus {
  String get label {
    switch (this) {
      case AgentStatus.active:
        return 'Actif';
      case AgentStatus.inactive:
        return 'Inactif';
      case AgentStatus.suspended:
        return 'Suspendu';
    }
  }
}

extension MobileOperatorExtension on MobileOperator {
  String get label {
    switch (this) {
      case MobileOperator.orange:
        return 'Orange';
      case MobileOperator.mtn:
        return 'MTN';
      case MobileOperator.moov:
        return 'Moov';
      case MobileOperator.other:
        return 'Autre';
    }
  }
}

