import 'machine_material_usage.dart';
import 'production_day.dart';
import 'production_event.dart';
import 'production_session_status.dart';
import 'material_consumption.dart';

/// Session de production avec suivi détaillé des matières machines et coûts.
/// (Anciennement avec suivi spécifique bobines).
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
    required this.machineMaterials,
    required this.quantiteProduite,
    required this.quantiteProduiteUnite,
    this.emballagesUtilises,
    this.machineMaterialCost,
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
  final int period;
  final DateTime heureDebut;
  final DateTime? heureFin;
  final int? indexCompteurInitialKwh;
  final int? indexCompteurFinalKwh;
  final double consommationCourant;
  final List<String> machinesUtilisees;
  final List<MachineMaterialUsage> machineMaterials;
  final int quantiteProduite;
  final String quantiteProduiteUnite;
  final int? emballagesUtilises;
  final int? machineMaterialCost;
  final int? coutEmballages;
  final int? coutElectricite;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? deletedAt;
  final String? deletedBy;
  final ProductionSessionStatus status;
  final List<ProductionEvent> events;
  final List<ProductionDay> productionDays;
  final String? cancelReason;

  /// Alias pour compatibilité descendante (transition)
  List<MachineMaterialUsage> get bobinesUtilisees => machineMaterials;
  int? get coutBobines => machineMaterialCost;

  double get dureeHeures {
    if (heureFin == null) {
      final difference = DateTime.now().difference(heureDebut);
      return difference.inMinutes / 60.0;
    }
    final difference = heureFin!.difference(heureDebut);
    return difference.inMinutes / 60.0;
  }

  int get coutTotal {
    final coutMat = machineMaterialCost ?? 0;
    final coutEmb = coutEmballages ?? 0;
    final coutElec = coutElectricite ?? 0;
    final coutPers = coutTotalPersonnel;
    return coutMat + coutEmb + coutElec + coutPers;
  }

  bool get estComplete {
    return machineMaterials.isNotEmpty &&
        machinesUtilisees.isNotEmpty &&
        (quantiteProduite > 0 || totalPacksProduitsJournalier > 0);
  }

  ProductionSessionStatus get calculatedStatus {
    if (quantiteProduite > 0 &&
        heureFin != null &&
        heureFin!.isAfter(heureDebut)) {
      return ProductionSessionStatus.completed;
    }
    if (machinesUtilisees.isNotEmpty || machineMaterials.isNotEmpty) {
      return ProductionSessionStatus.inProgress;
    }
    if (heureDebut.isBefore(DateTime.now())) {
      return ProductionSessionStatus.started;
    }
    return ProductionSessionStatus.draft;
  }

  ProductionSessionStatus get effectiveStatus {
    if (status == ProductionSessionStatus.cancelled) {
      return ProductionSessionStatus.cancelled;
    }
    if (status != ProductionSessionStatus.draft) {
      return status;
    }
    return calculatedStatus;
  }

  bool get toutesMatieresFinies {
    if (machineMaterials.isEmpty) return false;
    return machineMaterials.every((m) => m.estFinie);
  }

  bool get peutEtreFinalisee {
    return toutesMatieresFinies &&
        machineMaterials.isNotEmpty &&
        machinesUtilisees.length == machineMaterials.length;
  }

  int get totalPacksProduitsJournalier {
    if (productionDays.isEmpty) return 0;
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

  int get totalEmballagesUtilisesJournalier {
    if (consumptions.isNotEmpty) {
      return consumptions.fold<int>(0, (sum, c) => sum + c.quantity.toInt());
    }
    return productionDays.fold<int>(
      0,
      (sum, day) => sum + day.emballagesUtilises,
    );
  }

  int get coutTotalPersonnel {
    return productionDays.fold<int>(
      0,
      (sum, day) => sum + day.coutTotalPersonnel,
    );
  }

  bool get aEvenementsEnCours {
    return events.any((event) => !event.estTermine);
  }

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
    List<MachineMaterialUsage>? machineMaterials,
    int? quantiteProduite,
    String? quantiteProduiteUnite,
    int? emballagesUtilises,
    int? machineMaterialCost,
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
      machineMaterials: machineMaterials ?? this.machineMaterials,
      quantiteProduite: quantiteProduite ?? this.quantiteProduite,
      quantiteProduiteUnite:
          quantiteProduiteUnite ?? this.quantiteProduiteUnite,
      emballagesUtilises: emballagesUtilises ?? this.emballagesUtilises,
      machineMaterialCost: machineMaterialCost ?? this.machineMaterialCost,
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

  ProductionSession mergeWith(ProductionSession other) {
    if (other.id != id) return this;

    final thisUpdated = updatedAt ?? createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final otherUpdated =
        other.updatedAt ?? other.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

    final statusOrder = {
      ProductionSessionStatus.cancelled: -1,
      ProductionSessionStatus.draft: 0,
      ProductionSessionStatus.started: 1,
      ProductionSessionStatus.suspended: 2,
      ProductionSessionStatus.inProgress: 2,
      ProductionSessionStatus.completed: 4,
    };

    final thisStatusScore = statusOrder[status] ?? 0;
    final otherStatusScore = statusOrder[other.status] ?? 0;

    final mergedStatus =
        thisStatusScore >= otherStatusScore ? status : other.status;

    final Map<String, ProductionDay> mergedDays = {};
    for (final day in productionDays) {
      mergedDays[day.date.toIso8601String().split('T').first] = day;
    }
    for (final day in other.productionDays) {
      final key = day.date.toIso8601String().split('T').first;
      if (mergedDays.containsKey(key)) {
        final existing = mergedDays[key]!;
        if (day.updatedAt != null &&
            existing.updatedAt != null &&
            day.updatedAt!.isAfter(existing.updatedAt!)) {
          mergedDays[key] = day;
        }
      } else {
        mergedDays[key] = day;
      }
    }

    final Map<String, MachineMaterialUsage> mergedMaterials = {};
    for (final m in machineMaterials) {
      mergedMaterials[m.machineId] = m;
    }
    for (final m in other.machineMaterials) {
      if (mergedMaterials.containsKey(m.machineId)) {
        final existing = mergedMaterials[m.machineId]!;
        if (m.estFinie && !existing.estFinie) {
          mergedMaterials[m.machineId] = m;
        } else if (!m.estFinie && existing.estFinie) {
        } else if (m.dateInstallation.isAfter(existing.dateInstallation)) {
          mergedMaterials[m.machineId] = m;
        }
      } else {
        mergedMaterials[m.machineId] = m;
      }
    }

    final Map<String, ProductionEvent> mergedEvents = {};
    for (final e in events) {
      mergedEvents[e.id] = e;
    }
    for (final e in other.events) {
      mergedEvents[e.id] = e;
    }

    final useOther = otherUpdated.isAfter(thisUpdated);

    return copyWith(
      status: mergedStatus,
      productionDays: mergedDays.values.toList(),
      machineMaterials: mergedMaterials.values.toList(),
      events: mergedEvents.values.toList(),
      heureFin: (status == ProductionSessionStatus.completed)
          ? heureFin ?? other.heureFin
          : (other.status == ProductionSessionStatus.completed ? other.heureFin : null),
      quantiteProduite: useOther ? other.quantiteProduite : quantiteProduite,
      consommationCourant: useOther ? other.consommationCourant : consommationCourant,
      updatedAt: thisUpdated.isAfter(otherUpdated) ? thisUpdated : otherUpdated,
    );
  }

  factory ProductionSession.fromMap(
    Map<String, dynamic> map,
    String defaultEnterpriseId,
  ) {
    return ProductionSession(
      id: (map['localId'] as String?)?.trim().isNotEmpty == true 
          ? map['localId'] as String 
          : (map['id'] as String? ?? ''),
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
      machineMaterials: (map['machineMaterials'] as List? ?? (map['bobinesUtilisees'] as List? ?? []))
          .map((e) => MachineMaterialUsage.fromMap(e as Map<String, dynamic>))
          .toList(),
      quantiteProduite: (map['quantiteProduite'] as num?)?.toInt() ?? 0,
      quantiteProduiteUnite: map['quantiteProduiteUnite'] as String? ?? '',
      emballagesUtilises: (map['emballagesUtilises'] as num?)?.toInt(),
      machineMaterialCost: (map['machineMaterialCost'] as num? ?? (map['coutBobines'] as num?))?.toInt(),
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
      'machineMaterials': machineMaterials.map((e) => e.toMap()).toList(),
      'quantiteProduite': quantiteProduite,
      'quantiteProduiteUnite': quantiteProduiteUnite,
      'emballagesUtilises': emballagesUtilises,
      'machineMaterialCost': machineMaterialCost,
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
