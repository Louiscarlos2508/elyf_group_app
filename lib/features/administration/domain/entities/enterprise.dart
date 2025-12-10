/// Représente une entreprise du groupe ELYF
class Enterprise {
  const Enterprise({
    required this.id,
    required this.name,
    required this.type,
    this.description,
    this.address,
    this.phone,
    this.email,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Identifiant unique de l'entreprise
  final String id;

  /// Nom de l'entreprise
  final String name;

  /// Type d'entreprise (eau_minerale, gaz, orange_money, immobilier, boutique)
  final String type;

  /// Description de l'entreprise
  final String? description;

  /// Adresse de l'entreprise
  final String? address;

  /// Téléphone de contact
  final String? phone;

  /// Email de contact
  final String? email;

  /// Indique si l'entreprise est active
  final bool isActive;

  /// Date de création
  final DateTime? createdAt;

  /// Date de dernière mise à jour
  final DateTime? updatedAt;

  /// Crée une copie avec des champs modifiés
  Enterprise copyWith({
    String? id,
    String? name,
    String? type,
    String? description,
    String? address,
    String? phone,
    String? email,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Enterprise(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convertit en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'description': description,
      'address': address,
      'phone': phone,
      'email': email,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Crée depuis un Map (Firestore)
  factory Enterprise.fromMap(Map<String, dynamic> map) {
    return Enterprise(
      id: map['id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      description: map['description'] as String?,
      address: map['address'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }
}

/// Types d'entreprises disponibles
enum EnterpriseType {
  eauMinerale('eau_minerale', 'Eau Minérale'),
  gaz('gaz', 'Gaz'),
  orangeMoney('orange_money', 'Orange Money'),
  immobilier('immobilier', 'Immobilier'),
  boutique('boutique', 'Boutique');

  const EnterpriseType(this.id, this.label);

  final String id;
  final String label;
}

