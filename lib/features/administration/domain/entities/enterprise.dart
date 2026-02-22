import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter/material.dart' show IconData, Color, Colors, Icons;

/// Modules disponibles dans l'écosystème ELYF
enum EnterpriseModule {
  group('group', 'Groupe ELYF', Icons.account_balance, Colors.blue),
  gaz('gaz', 'Gaz', Icons.local_gas_station, Colors.orange),
  eau('eau_minerale', 'Eau Minérale', Icons.water_drop, Colors.blue),
  immobilier('immobilier', 'Immobilier', Icons.home_work, Colors.brown),
  boutique('boutique', 'Boutique', Icons.store, Colors.green),
  mobileMoney('orange_money', 'Mobile Money', Icons.account_balance_wallet, Colors.teal);

  const EnterpriseModule(this.id, this.label, this.icon, this.color);
  final String id;
  final String label;
  final IconData icon;
  final Color color;

  /// Vérifier si le module supporte une hiérarchie N-niveaux
  bool get supportsHierarchy => this == gaz || this == mobileMoney || this == group;
}

/// Types d'entreprises disponibles (hiérarchie multi-tenant)
enum EnterpriseType {
  // Groupe
  group('group', 'Groupe', 'Groupe ELYF', EnterpriseModule.group, isMain: true),
  
  // Gaz
  gasCompany('gas_company', 'Société Gaz', 'Entreprise de distribution de gaz', EnterpriseModule.gaz, isMain: true),
  gasPointOfSale('gas_pos', 'Point de vente Gaz', 'Point de vente de bouteilles de gaz', EnterpriseModule.gaz),
  gasWarehouse('gas_warehouse', 'Dépôt Gaz', 'Dépôt de stockage de bouteilles', EnterpriseModule.gaz),
  
  // Eau
  waterEntity('water_entity', 'Unité Eau', 'Unité de production ou distribution d\'eau', EnterpriseModule.eau, isMain: true),
  waterFactory('water_factory', 'Usine Eau', 'Usine de production d\'eau', EnterpriseModule.eau),
  waterWarehouse('water_warehouse', 'Dépôt Eau', 'Dépôt de stockage d\'eau', EnterpriseModule.eau),
  waterPointOfSale('water_pos', 'Point de vente Eau', 'Point de vente d\'eau', EnterpriseModule.eau),
  
  // Immobilier
  realEstateAgency('real_estate_agency', 'Agence Immobilière', 'Agence immobilière', EnterpriseModule.immobilier, isMain: true),
  realEstateBranch('real_estate_branch', 'Succursale Immobilière', 'Succursale d\'agence', EnterpriseModule.immobilier),
  
  // Boutique
  shop('shop', 'Boutique', 'Boutique de vente', EnterpriseModule.boutique, isMain: true),
  shopBranch('shop_branch', 'Succursale Boutique', 'Succursale de boutique', EnterpriseModule.boutique),
  
  // Mobile Money
  mobileMoneyAgent('mm_agent', 'Agent Mobile Money', 'Agent principal', EnterpriseModule.mobileMoney, isMain: true),
  mobileMoneySubAgent('mm_sub_agent', 'Sous-Agent', 'Sous-agent Mobile Money', EnterpriseModule.mobileMoney),
  mobileMoneyDistributor('mm_distributor', 'Distributeur', 'Distributeur Mobile Money', EnterpriseModule.mobileMoney),
  mobileMoneyKiosk('mm_kiosk', 'Kiosque', 'Kiosque Mobile Money', EnterpriseModule.mobileMoney),
  
  // Générique
  pointOfSale('pos', 'Point de vente', 'Point de vente générique', EnterpriseModule.gaz);

  const EnterpriseType(this.id, this.label, this.description, this.module, {this.isMain = false});

  final String id;
  final String label;
  final String description;
  final EnterpriseModule module;
  final bool isMain;

  /// Vérifier si ce type supporte des sous-entités
  /// Règle métier : Seul Gaz et Mobile Money supportent une hiérarchie N-niveaux.
  bool get canHaveChildren {
    if (this == group) return true;
    return isMain && module.supportsHierarchy;
  }


  /// Obtenir le type depuis l'ID (avec support des anciens IDs pour rétrocompatibilité)
  static EnterpriseType fromId(String id) {
    // Mapping des anciens IDs vers les nouveaux types
    const legacyMapping = {
      'eau_minerale': 'water_entity',
      'gaz': 'gas_company',
      'orange_money': 'mm_agent',
      'immobilier': 'real_estate_agency',
      'boutique': 'shop',
      'company': 'gas_company', // Remplacer le générique par Gaz par défaut ou autre
    };
    
    // Vérifier si c'est un ancien ID
    final mappedId = legacyMapping[id] ?? id;
    
    return EnterpriseType.values.firstWhere(
      (type) => type.id == mappedId,
      orElse: () => EnterpriseType.gasCompany,
    );
  }

  /// Vérifier si le type appartient au module Gaz
  bool get isGas => module == EnterpriseModule.gaz;

  /// Vérifier si le type appartient au module Eau
  bool get isWater => module == EnterpriseModule.eau;

  /// Vérifier si le type appartient au module Immobilier
  bool get isRealEstate => module == EnterpriseModule.immobilier;

  /// Vérifier si le type appartient au module Boutique
  bool get isShop => module == EnterpriseModule.boutique;

  /// Vérifier si c'est un type Mobile Money
  bool get isMobileMoney => module == EnterpriseModule.mobileMoney;

  /// Vérifier si c'est un type de point de vente
  bool get isPointOfSale => [
    gasPointOfSale,
    waterPointOfSale,
    shop,
    shopBranch,
  ].contains(this);

  /// Obtenir une icône représentative du type d'entité
  IconData get icon {
    if (this == group) return Icons.account_balance;
    if (isMain) return Icons.business;
    if (isPointOfSale) return Icons.store_mall_directory;
    if (this == mobileMoneyKiosk) return Icons.door_front_door;
    if (this == gasWarehouse || this == waterWarehouse) return Icons.warehouse;
    return Icons.location_on;
  }
}

/// Représente une entreprise du groupe ELYF avec support multi-tenant N-niveaux
class Enterprise extends Equatable {
  const Enterprise({
    required this.id,
    required this.name,
    required this.type,
    this.parentEnterpriseId,
    this.hierarchyLevel = 0,
    this.hierarchyPath = '',
    this.ancestorIds = const [],
    this.moduleId,
    this.metadata = const {},
    this.latitude,
    this.longitude,
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

  /// Type d'entreprise (enum)
  final EnterpriseType type;

  /// ID de l'entreprise parente (null si racine)
  final String? parentEnterpriseId;
  
  /// Niveau dans la hiérarchie (0 = racine, 1 = enfant, 2 = petit-enfant, etc.)
  final int hierarchyLevel;
  
  /// Chemin hiérarchique complet (ex: "/elyf-groupe/elyf-gaz/pos-douala")
  final String hierarchyPath;
  
  /// Liste des IDs de tous les ancêtres (du plus ancien au plus récent)
  final List<String> ancestorIds;
  
  /// ID du module propriétaire (gaz, eau, immobilier, boutique, orange_money)
  final String? moduleId;
  
  /// Métadonnées spécifiques au type d'entreprise
  /// Exemples:
  /// - Mobile Money: floatBalance, commissionRate, zone, phoneNumber
  /// - Point de vente: stockCapacity, currentStock, manager, openingHours
  /// - Usine: productionCapacity, machineCount
  final Map<String, dynamic> metadata;
  
  /// Latitude (géolocalisation)
  final double? latitude;
  
  /// Longitude (géolocalisation)
  final double? longitude;

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
  
  /// Vérifier si c'est une entreprise racine
  bool get isRoot => hierarchyLevel == 0;
  
  /// Vérifier si c'est un point de vente
  bool get isPointOfSale => type.isPointOfSale;
  
  /// Vérifier si c'est lié au Mobile Money
  bool get isMobileMoney => type.isMobileMoney;

  /// Vérifier si cette entreprise peut avoir des sous-entreprises (enfants)
  /// Règle métier : Seul le groupe (racine) et les entités principales Gaz ou Mobile Money peuvent avoir des enfants.
  bool get supportsHierarchy => type.canHaveChildren;

  /// Crée une copie avec des champs modifiés
  Enterprise copyWith({
    String? id,
    String? name,
    EnterpriseType? type,
    String? parentEnterpriseId,
    int? hierarchyLevel,
    String? hierarchyPath,
    List<String>? ancestorIds,
    String? moduleId,
    Map<String, dynamic>? metadata,
    double? latitude,
    double? longitude,
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
      parentEnterpriseId: parentEnterpriseId ?? this.parentEnterpriseId,
      hierarchyLevel: hierarchyLevel ?? this.hierarchyLevel,
      hierarchyPath: hierarchyPath ?? this.hierarchyPath,
      ancestorIds: ancestorIds ?? this.ancestorIds,
      moduleId: moduleId ?? this.moduleId,
      metadata: metadata ?? this.metadata,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
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
      'type': type.id,
      'parentEnterpriseId': parentEnterpriseId,
      'hierarchyLevel': hierarchyLevel,
      'hierarchyPath': hierarchyPath,
      'ancestorIds': ancestorIds,
      'moduleId': moduleId,
      'metadata': metadata,
      'latitude': latitude,
      'longitude': longitude,
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
      type: EnterpriseType.fromId(map['type'] as String),
      parentEnterpriseId: map['parentEnterpriseId'] as String?,
      hierarchyLevel: map['hierarchyLevel'] as int? ?? 0,
      hierarchyPath: map['hierarchyPath'] as String? ?? '',
      ancestorIds: (map['ancestorIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? const [],
      moduleId: map['moduleId'] as String?,
      metadata: (map['metadata'] as Map<String, dynamic>?) ?? const {},
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      description: map['description'] as String?,
      address: map['address'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
    );
  }

  /// Convertit un timestamp Firestore (Timestamp ou String) en DateTime
  static DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    if (timestamp is String) {
      return DateTime.tryParse(timestamp);
    }
    return null;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        parentEnterpriseId,
        hierarchyLevel,
        hierarchyPath,
        ancestorIds,
        moduleId,
        metadata,
        latitude,
        longitude,
        description,
        address,
        phone,
        email,
        isActive,
        createdAt,
        updatedAt,
      ];
}
