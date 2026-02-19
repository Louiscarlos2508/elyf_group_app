import 'bobine_usage.dart';
import 'production_day.dart';
import 'production_event.dart';
import 'production_session_status.dart';
import 'material_consumption.dart';

/// Session de production avec suivi détaillé des bobines, machines et coûts.
class ProductionSession {
  const ProductionSession({
    required this.id,
    required this.enterpriseId,
    required this.date,
    required this.period,
    required this.heureDebut,
    this.heureFin,
    this.indexCompteurInitialKwh,
    this.indexCompteurFinalKwh,
    required this.consommationCourant,
    required this.machinesUtilisees,
    required this.bobinesUtilisees,
    required this.quantiteProduite,
    required this.quantiteProduiteUnite,
    this.emballagesUtilises,
    this.coutBobines,
    this.coutEmballages,
    this.coutElectricite,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.deletedAt,
    this.deletedBy,
    this.status = ProductionSessionStatus.draft,
    this.cancelReason,
    this.events = const [],
    this.productionDays = const [],
  });

  final String id;
  final String enterpriseId;
  final DateTime date;
  final int period; // Période de production (pour compatibilité)
  final DateTime heureDebut;
  final DateTime? heureFin; // null jusqu'à la finalisation de la production
  final int?
  indexCompteurInitialKwh; // Index compteur électrique initial (kWh) au démarrage
  final int?
  indexCompteurFinalKwh; // Index compteur électrique final (kWh) à la fin
  final double
  consommationCourant; // kWh (calculé si indexCompteurInitialKwh et indexCompteurFinalKwh sont définis)
  final List<String> machinesUtilisees; // IDs des machines
  final List<BobineUsage> bobinesUtilisees;
  final int quantiteProduite; // Quantité produite
  final String quantiteProduiteUnite; // Unité (ex: "pack", "sachet")
  final int? emballagesUtilises; // Nombre d'emballages utilisés (packs)
  final int? coutBobines; // Coût total des bobines utilisées (CFA)
  final int? coutEmballages; // Coût total des emballages utilisés (CFA)
  final int? coutElectricite; // Coût de l'électricité (CFA)
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? deletedAt;
  final String? deletedBy;
  final ProductionSessionStatus status;
  final List<ProductionEvent> events; // Événements (pannes, coupures, arrêts)
  final List<ProductionDay>
  productionDays; // Jours de production avec personnel
  final String? cancelReason;

  /// Calcule la durée de production en heures
  double get dureeHeures {
    if (heureFin == null) {
      // Si pas encore finalisée, calculer depuis le début jusqu'à maintenant
      final difference = DateTime.now().difference(heureDebut);
      return difference.inMinutes / 60.0;
    }
    final difference = heureFin!.difference(heureDebut);
    return difference.inMinutes / 60.0;
  }

  /// Calcule le coût total de la session (bobines + emballages + électricité + personnel)
  int get coutTotal {
    final coutBob = coutBobines ?? 0;
    final coutEmb = coutEmballages ?? 0;
    final coutElec = coutElectricite ?? 0;
    final coutPers = coutTotalPersonnel;
    return coutBob + coutEmb + coutElec + coutPers;
  }

  /// Vérifie si la session est complète (toutes les données nécessaires)
  bool get estComplete {
    return bobinesUtilisees.isNotEmpty &&
        machinesUtilisees.isNotEmpty &&
        (quantiteProduite > 0 || totalPacksProduitsJournalier > 0);
  }

  /// Calcule le statut de progression basé sur les données disponibles
  ProductionSessionStatus get calculatedStatus {
    if (quantiteProduite > 0 &&
        heureFin != null &&
        heureFin!.isAfter(heureDebut)) {
      return ProductionSessionStatus.completed;
    }
    if (machinesUtilisees.isNotEmpty || bobinesUtilisees.isNotEmpty) {
      return ProductionSessionStatus.inProgress;
    }
    if (heureDebut.isBefore(DateTime.now())) {
      return ProductionSessionStatus.started;
    }
    return ProductionSessionStatus.draft;
  }

  /// Retourne le statut effectif (toujours utiliser le statut enregistré, sauf s'il est draft)
  ///
  /// Le statut enregistré doit toujours être utilisé pour éviter les conflits.
  /// Si le statut est draft, on peut calculer le statut à partir des données.
  ProductionSessionStatus get effectiveStatus {
    // Si annulée, on reste annulée
    if (status == ProductionSessionStatus.cancelled) {
      return ProductionSessionStatus.cancelled;
    }
    // Utiliser le statut enregistré s'il existe et n'est pas draft
    // Cela garantit que le statut explicitement défini (notamment "completed") est toujours respecté
    if (status != ProductionSessionStatus.draft) {
      return status;
    }
    // Si le statut est draft, calculer le statut à partir des données disponibles
    return calculatedStatus;
  }

  /// Vérifie si toutes les bobines sont complètement finies.
  /// Une production ne peut se terminer que si toutes les bobines sont finies.
  bool get toutesBobinesFinies {
    if (bobinesUtilisees.isEmpty) return false;
    return bobinesUtilisees.every((bobine) => bobine.estFinie);
  }

  /// Vérifie si la production peut être finalisée.
  /// Conditions : toutes les boubines doivent être finies.
  bool get peutEtreFinalisee {
    return toutesBobinesFinies &&
        bobinesUtilisees.isNotEmpty &&
        machinesUtilisees.length == bobinesUtilisees.length;
  }

  /// Nombre total de packs produits au cours de la session.
  /// Priorise la somme des productions journalières détaillées si présentes.
  int get totalPacksProduitsJournalier {
    if (productionDays.isEmpty) return 0;
    
    // Si on a des produits finis détaillés dans les jours, on les somme par produit 
    // ou on retourne simplement le total brut des quantités produites.
    final hasDetailedProduction = productionDays.any((d) => d.producedItems.isNotEmpty);
    if (hasDetailedProduction) {
      return productionDays.fold<int>(
        0,
        (sum, day) => sum + day.producedItems.fold<int>(0, (s, item) => s + item.quantity.toInt()),
      );
    }

    return productionDays.fold<int>(
      0,
      (sum, day) => sum + day.packsProduits,
    );
  }

  /// Liste de tous les produits finis produits pendant la session (agrégée).
  List<MaterialConsumption> get producedItems {
    final Map<String, MaterialConsumption> totals = {};
    for (final day in productionDays) {
      for (final item in day.producedItems) {
        if (totals.containsKey(item.productId)) {
          final existing = totals[item.productId]!;
          totals[item.productId] = existing.copyWith(
            quantity: existing.quantity + item.quantity,
          );
        } else {
          totals[item.productId] = item;
        }
      }
    }
    return totals.values.toList();
  }

  /// Liste de toutes les matières consommées pendant la session (agrégée).
  List<MaterialConsumption> get consumptions {
    final Map<String, MaterialConsumption> totals = {};
    for (final day in productionDays) {
      for (final item in day.consumptions) {
        if (totals.containsKey(item.productId)) {
          final existing = totals[item.productId]!;
          totals[item.productId] = existing.copyWith(
            quantity: existing.quantity + item.quantity,
          );
        } else {
          totals[item.productId] = item;
        }
      }
    }
    return totals.values.toList();
  }

  /// Nombre total d'emballages utilisés au cours de la session.
  /// Priorise le nouveau champ détaillé `consumptions`.
  int get totalEmballagesUtilisesJournalier {
    // Si on a les nouvelles consommations détaillées, on les préfère
    if (consumptions.isNotEmpty) {
      return consumptions.fold<int>(0, (sum, c) => sum + c.quantity.toInt());
    }
    // Sinon on retombe sur l'ancien champ
    return productionDays.fold<int>(
      0,
      (sum, day) => sum + day.emballagesUtilises,
    );
  }

  /// Calcule le coût total du personnel pour tous les jours de production.
  int get coutTotalPersonnel {
    return productionDays.fold<int>(
      0,
      (sum, day) => sum + day.coutTotalPersonnel,
    );
  }

  /// Vérifie s'il y a des événements en cours (non terminés).
  bool get aEvenementsEnCours {
    return events.any((event) => !event.estTermine);
  }

  /// Récupère les événements d'un type donné.
  List<ProductionEvent> evenementsParType(ProductionEventType type) {
    return events.where((event) => event.type == type).toList();
  }

  bool get isDeleted => deletedAt != null;

  ProductionSession copyWith({
    String? id,
    String? enterpriseId,
    DateTime? date,
    int? period,
    DateTime? heureDebut,
    DateTime? heureFin,
    int? indexCompteurInitialKwh,
    int? indexCompteurFinalKwh,
    double? consommationCourant,
    List<String>? machinesUtilisees,
    List<BobineUsage>? bobinesUtilisees,
    int? quantiteProduite,
    String? quantiteProduiteUnite,
    int? emballagesUtilises,
    int? coutBobines,
    int? coutEmballages,
    int? coutElectricite,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    DateTime? deletedAt,
    String? deletedBy,
    ProductionSessionStatus? status,
    String? cancelReason,
    List<ProductionEvent>? events,
    List<ProductionDay>? productionDays,
  }) {
    return ProductionSession(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      date: date ?? this.date,
      period: period ?? this.period,
      heureDebut: heureDebut ?? this.heureDebut,
      heureFin: heureFin ?? this.heureFin,
      indexCompteurInitialKwh:
          indexCompteurInitialKwh ?? this.indexCompteurInitialKwh,
      indexCompteurFinalKwh:
          indexCompteurFinalKwh ?? this.indexCompteurFinalKwh,
      consommationCourant: consommationCourant ?? this.consommationCourant,
      machinesUtilisees: machinesUtilisees ?? this.machinesUtilisees,
      bobinesUtilisees: bobinesUtilisees ?? this.bobinesUtilisees,
      quantiteProduite: quantiteProduite ?? this.quantiteProduite,
      quantiteProduiteUnite:
          quantiteProduiteUnite ?? this.quantiteProduiteUnite,
      emballagesUtilises: emballagesUtilises ?? this.emballagesUtilises,
      coutBobines: coutBobines ?? this.coutBobines,
      coutEmballages: coutEmballages ?? this.coutEmballages,
      coutElectricite: coutElectricite ?? this.coutElectricite,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      status: status ?? this.status,
      cancelReason: cancelReason ?? this.cancelReason,
      events: events ?? this.events,
      productionDays: productionDays ?? this.productionDays,
    );
  }

  factory ProductionSession.fromMap(
    Map<String, dynamic> map,
    String defaultEnterpriseId,
  ) {
    return ProductionSession(
      id: map['id'] as String? ?? map['localId'] as String,
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      date: DateTime.parse(map['date'] as String),
      period: (map['period'] as num?)?.toInt() ?? 0,
      heureDebut: DateTime.parse(map['heureDebut'] as String),
      heureFin: map['heureFin'] != null
          ? DateTime.parse(map['heureFin'] as String)
          : null,
      indexCompteurInitialKwh: (map['indexCompteurInitialKwh'] as num?)?.toInt(),
      indexCompteurFinalKwh: (map['indexCompteurFinalKwh'] as num?)?.toInt(),
      consommationCourant: (map['consommationCourant'] as num?)?.toDouble() ?? 0,
      machinesUtilisees: List<String>.from(map['machinesUtilisees'] as List? ?? []),
      bobinesUtilisees: (map['bobinesUtilisees'] as List? ?? [])
          .map((e) => BobineUsage.fromMap(e as Map<String, dynamic>))
          .toList(),
      quantiteProduite: (map['quantiteProduite'] as num?)?.toInt() ?? 0,
      quantiteProduiteUnite: map['quantiteProduiteUnite'] as String? ?? '',
      emballagesUtilises: (map['emballagesUtilises'] as num?)?.toInt(),
      coutBobines: (map['coutBobines'] as num?)?.toInt(),
      coutEmballages: (map['coutEmballages'] as num?)?.toInt(),
      coutElectricite: (map['coutElectricite'] as num?)?.toInt(),
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      createdBy: map['createdBy'] as String?,
      updatedBy: map['updatedBy'] as String?,
      deletedAt: map['deletedAt'] != null
          ? DateTime.parse(map['deletedAt'] as String)
          : null,
      deletedBy: map['deletedBy'] as String?,
      status: ProductionSessionStatus.values.byName(
        map['status'] as String? ?? 'draft',
      ),
      cancelReason: map['cancelReason'] as String?,
      events: (map['events'] as List? ?? [])
          .map((e) => ProductionEvent.fromMap(e as Map<String, dynamic>))
          .toList(),
      productionDays: (map['productionDays'] as List? ?? [])
          .map((e) => ProductionDay.fromMap(e as Map<String, dynamic>, defaultEnterpriseId))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'date': date.toIso8601String(),
      'period': period,
      'heureDebut': heureDebut.toIso8601String(),
      'heureFin': heureFin?.toIso8601String(),
      'indexCompteurInitialKwh': indexCompteurInitialKwh,
      'indexCompteurFinalKwh': indexCompteurFinalKwh,
      'consommationCourant': consommationCourant,
      'machinesUtilisees': machinesUtilisees,
      'bobinesUtilisees': bobinesUtilisees.map((e) => e.toMap()).toList(),
      'quantiteProduite': quantiteProduite,
      'quantiteProduiteUnite': quantiteProduiteUnite,
      'emballagesUtilises': emballagesUtilises,
      'coutBobines': coutBobines,
      'coutEmballages': coutEmballages,
      'coutElectricite': coutElectricite,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
      'status': status.name,
      'cancelReason': cancelReason,
      'events': events.map((e) => e.toMap()).toList(),
      'productionDays': productionDays.map((e) => e.toMap()).toList(),
    };
  }
}
