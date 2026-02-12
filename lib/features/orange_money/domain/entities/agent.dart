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
    this.type = AgentType.internal,
    this.attachmentUrls = const [],
    this.notes,
    this.deletedAt,
    this.deletedBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String phoneNumber;
  final String simNumber;
  final MobileOperator operator;
  final int liquidity; // Liquidité disponible en FCFA
  final double
  commissionRate; // Taux de commission en pourcentage (ex: 2.5 pour 2.5%)
  final AgentStatus status;
  final String enterpriseId;
  final AgentType type;
  final List<String> attachmentUrls;
  final String? notes;
  final DateTime? deletedAt;
  final String? deletedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isDeleted => deletedAt != null;

  /// Vérifie si l'agent est actif.
  bool get isActive => status == AgentStatus.active;

  /// Vérifie si l'agent a une liquidité faible (en dessous d'un seuil).
  bool isLowLiquidity(int threshold) => liquidity < threshold;

  Agent copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? simNumber,
    MobileOperator? operator,
    int? liquidity,
    double? commissionRate,
    AgentStatus? status,
    String? enterpriseId,
    AgentType? type,
    List<String>? attachmentUrls,
    String? notes,
    DateTime? deletedAt,
    String? deletedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Agent(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      simNumber: simNumber ?? this.simNumber,
      operator: operator ?? this.operator,
      liquidity: liquidity ?? this.liquidity,
      commissionRate: commissionRate ?? this.commissionRate,
      status: status ?? this.status,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      type: type ?? this.type,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      notes: notes ?? this.notes,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Agent.fromMap(Map<String, dynamic> map, String defaultEnterpriseId) {
    return Agent(
      id: map['id'] as String? ?? map['localId'] as String,
      name: map['name'] as String,
      phoneNumber: map['phoneNumber'] as String,
      simNumber: map['simNumber'] as String,
      operator: MobileOperator.values.byName(map['operator'] as String),
      liquidity: (map['liquidity'] as num).toInt(),
      commissionRate: (map['commissionRate'] as num).toDouble(),
      status: AgentStatus.values.byName(map['status'] as String),
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      type: map['type'] != null
          ? AgentType.values.byName(map['type'] as String)
          : AgentType.internal,
      attachmentUrls: (map['attachmentUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      notes: map['notes'] as String?,
      deletedAt: map['deletedAt'] != null
          ? DateTime.parse(map['deletedAt'] as String)
          : null,
      deletedBy: map['deletedBy'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'simNumber': simNumber,
      'operator': operator.name,
      'liquidity': liquidity,
      'commissionRate': commissionRate,
      'status': status.name,
      'enterpriseId': enterpriseId,
      'type': type.name,
      'attachmentUrls': attachmentUrls,
      'notes': notes,
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

enum AgentStatus { active, inactive, suspended }

enum AgentType { internal, external }

enum MobileOperator { orange, mtn, moov, other }

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

extension AgentTypeExtension on AgentType {
  String get label {
    switch (this) {
      case AgentType.internal:
        return 'Succursale';
      case AgentType.external:
        return 'Partenaire';
    }
  }
}
