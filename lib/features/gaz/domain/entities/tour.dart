import 'package:elyf_groupe_app/features/gaz/domain/entities/transport_expense.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/tour_site_interaction.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/site_logistics_record.dart'; // Pour compatibilité si besoin

export 'transport_expense.dart';
export 'tour_site_interaction.dart';

/// Statut d'un tour.
enum TourStatus {
  open('En cours'),
  collecting('Collecte'),
  recharging('Recharge'),
  delivering('Livraison'),
  closing('Clôture'),
  closed('Clôturé'),
  cancelled('Annulé');

  const TourStatus(this.label);
  final String label;
}

/// Représente un tour d'approvisionnement (Journal du Camion).
///
/// Le camion collecte des vides, livre des pleines aux POS et Grossistes,
/// et se recharge chez le fournisseur.
class Tour {
  const Tour({
    required this.id,
    required this.enterpriseId,
    required this.tourDate,
    required this.status,
    this.initialFullBottles = const {},
    this.initialEmptyBottles = const {},
    this.remainingFullBottles = const {},
    this.remainingEmptyBottles = const {},
    List<TourSiteInteraction>? siteInteractions,
    List<TransportExpense>? transportExpenses,
    this.fullBottlesReceived = const {},
    this.emptyBottlesReturned = const {},
    this.gasPurchaseCost,
    this.supplierName,
    this.transportCompletedDate,
    this.receptionCompletedDate,
    this.closureDate,
    this.cancelledDate,
    this.notes,
    this.updatedAt,
    this.createdAt,
    this.deletedAt,
    this.deletedBy,
  })  : _siteInteractions = siteInteractions,
        _transportExpenses = transportExpenses;

  final String id;
  final String enterpriseId;
  final DateTime tourDate;
  final TourStatus status;

  /// Stock initial dans le camion au départ.
  final Map<int, int> initialFullBottles;
  final Map<int, int> initialEmptyBottles;

  /// Stock restant dans le camion à la fin (report ou résidu).
  final Map<int, int> remainingFullBottles;
  final Map<int, int> remainingEmptyBottles;

  /// Liste des passages (POS, Grossistes, etc.).
  final List<TourSiteInteraction>? _siteInteractions;
  List<TourSiteInteraction> get siteInteractions => _siteInteractions ?? const [];

  /// Dépenses logistiques (carburant, péage, etc.).
  final List<TransportExpense>? _transportExpenses;
  List<TransportExpense> get transportExpenses => _transportExpenses ?? const [];

  /// Échange Fournisseur (Recharge).
  final Map<int, int> fullBottlesReceived;
  final Map<int, int> emptyBottlesReturned;
  final double? gasPurchaseCost;
  final String? supplierName;

  /// Dates de complétion des étapes.
  final DateTime? transportCompletedDate;
  final DateTime? receptionCompletedDate;
  final DateTime? closureDate;
  final DateTime? cancelledDate;

  final String? notes;
  final DateTime? updatedAt;
  final DateTime? createdAt;
  final DateTime? deletedAt;
  final String? deletedBy;

  Tour copyWith({
    String? id,
    String? enterpriseId,
    DateTime? tourDate,
    TourStatus? status,
    Map<int, int>? initialFullBottles,
    Map<int, int>? initialEmptyBottles,
    Map<int, int>? remainingFullBottles,
    Map<int, int>? remainingEmptyBottles,
    List<TourSiteInteraction>? siteInteractions,
    List<TransportExpense>? transportExpenses,
    Map<int, int>? fullBottlesReceived,
    Map<int, int>? emptyBottlesReturned,
    double? gasPurchaseCost,
    String? supplierName,
    DateTime? transportCompletedDate,
    DateTime? receptionCompletedDate,
    DateTime? closureDate,
    DateTime? cancelledDate,
    String? notes,
    DateTime? updatedAt,
    DateTime? createdAt,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return Tour(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      tourDate: tourDate ?? this.tourDate,
      status: status ?? this.status,
      initialFullBottles: initialFullBottles ?? this.initialFullBottles,
      initialEmptyBottles: initialEmptyBottles ?? this.initialEmptyBottles,
      remainingFullBottles: remainingFullBottles ?? this.remainingFullBottles,
      remainingEmptyBottles: remainingEmptyBottles ?? this.remainingEmptyBottles,
      siteInteractions: siteInteractions ?? _siteInteractions,
      transportExpenses: transportExpenses ?? _transportExpenses,
      fullBottlesReceived: fullBottlesReceived ?? this.fullBottlesReceived,
      emptyBottlesReturned: emptyBottlesReturned ?? this.emptyBottlesReturned,
      gasPurchaseCost: gasPurchaseCost ?? this.gasPurchaseCost,
      supplierName: supplierName ?? this.supplierName,
      transportCompletedDate: transportCompletedDate ?? this.transportCompletedDate,
      receptionCompletedDate: receptionCompletedDate ?? this.receptionCompletedDate,
      closureDate: closureDate ?? this.closureDate,
      cancelledDate: cancelledDate ?? this.cancelledDate,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  factory Tour.fromMap(Map<String, dynamic> map, String defaultEnterpriseId) {
    final validLocalId = map['localId'] as String?;
    final objectId = (validLocalId != null && validLocalId.trim().isNotEmpty)
        ? validLocalId
        : (map['id'] as String? ?? '');

    return Tour(
      id: objectId,
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      tourDate: DateTime.parse(map['tourDate'] as String),
      status: _parseStatus(map['status'] as String? ?? 'open'),
      initialFullBottles: _parseMapIntInt(map['initialFullBottles']),
      initialEmptyBottles: _parseMapIntInt(map['initialEmptyBottles']),
      remainingFullBottles: _parseMapIntInt(map['remainingFullBottles']),
      remainingEmptyBottles: _parseMapIntInt(map['remainingEmptyBottles']),
      siteInteractions: (map['siteInteractions'] as List<dynamic>?)
          ?.map((s) => TourSiteInteraction.fromMap(s as Map<String, dynamic>))
          .toList(),
      transportExpenses: (map['transportExpenses'] as List<dynamic>?)
          ?.map((e) => TransportExpense.fromMap(e as Map<String, dynamic>))
          .toList(),
      fullBottlesReceived: _parseMapIntInt(map['fullBottlesReceived']),
      emptyBottlesReturned: _parseMapIntInt(map['emptyBottlesReturned']),
      gasPurchaseCost: (map['gasPurchaseCost'] as num?)?.toDouble(),
      supplierName: map['supplierName'] as String?,
      transportCompletedDate: _parseDate(map['transportCompletedDate']),
      receptionCompletedDate: _parseDate(map['receptionCompletedDate']),
      closureDate: _parseDate(map['closureDate']),
      cancelledDate: _parseDate(map['cancelledDate']),
      notes: map['notes'] as String?,
      updatedAt: _parseDate(map['updatedAt']),
      createdAt: _parseDate(map['createdAt']),
      deletedAt: _parseDate(map['deletedAt']),
      deletedBy: map['deletedBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'localId': id, // Explicitly include localId to avoid loss during sync
      'enterpriseId': enterpriseId,
      'tourDate': tourDate.toIso8601String(),
      'status': status.name,
      'initialFullBottles': initialFullBottles.map((k, v) => MapEntry(k.toString(), v)),
      'initialEmptyBottles': initialEmptyBottles.map((k, v) => MapEntry(k.toString(), v)),
      'remainingFullBottles': remainingFullBottles.map((k, v) => MapEntry(k.toString(), v)),
      'remainingEmptyBottles': remainingEmptyBottles.map((k, v) => MapEntry(k.toString(), v)),
      'siteInteractions': siteInteractions.map((s) => s.toMap()).toList(),
      'transportExpenses': transportExpenses.map((e) => e.toMap()).toList(),
      'fullBottlesReceived': fullBottlesReceived.map((k, v) => MapEntry(k.toString(), v)),
      'emptyBottlesReturned': emptyBottlesReturned.map((k, v) => MapEntry(k.toString(), v)),
      'gasPurchaseCost': gasPurchaseCost,
      'supplierName': supplierName,
      'transportCompletedDate': transportCompletedDate?.toIso8601String(),
      'receptionCompletedDate': receptionCompletedDate?.toIso8601String(),
      'closureDate': closureDate?.toIso8601String(),
      'cancelledDate': cancelledDate?.toIso8601String(),
      'notes': notes,
      'updatedAt': updatedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
    };
  }

  static Map<int, int> _parseMapIntInt(dynamic map) {
    if (map == null || map is! Map) return const {};
    return map.map((k, v) => MapEntry(int.parse(k.toString()), (v as num).toInt()));
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.parse(value as String);
  }

  static TourStatus _parseStatus(String status) {
    try {
      return TourStatus.values.byName(status);
    } catch (_) {
      // Migration logic for old statuses
      if (status == 'loading' || status == 'transport' || status == 'reception') return TourStatus.open;
      if (status == 'closure') return TourStatus.closed;
      return TourStatus.open;
    }
  }

  bool get isDeleted => deletedAt != null;

  // --- Getters de compatibilité et calculs ---

  /// Total des dépenses (Transport + Achat Gaz + Frais divers).
  double get totalExpenses => totalTransportExpenses + (gasPurchaseCost ?? 0.0) + totalLoadingFees + totalUnloadingFees + totalExchangeFees + additionalInvoiceFees;

  /// Calcule le total des dépenses en incluant une estimation du coût de recharge si non renseigné.
  double calculateTotalExpenses(Map<int, double> purchasePrices) => 
      totalTransportExpenses + (gasPurchaseCost ?? calculateEstimatedGasPurchaseCost(purchasePrices)) + totalLoadingFees + totalUnloadingFees + totalExchangeFees + additionalInvoiceFees;

  double calculateEstimatedGasPurchaseCost(Map<int, double> purchasePrices) {
    try {
      double total = 0;
      fullBottlesReceived.forEach((weight, qty) {
        total += qty * (purchasePrices[weight] ?? 0.0);
      });
      return total;
    } catch (_) {
      return 0.0;
    }
  }

  int get totalBottlesReceived {
    try {
      return fullBottlesReceived.values.fold(0, (sum, q) => sum + q);
    } catch (_) {
      return 0;
    }
  }

  /// Calcule théoriquement le nombre de pleines à recevoir (Somme des vides collectés sur sites).
  Map<int, int> get theoreticalFullBottlesReceived {
    final result = <int, int>{};
    for (final record in siteInteractions) {
      record.emptyBottlesCollected.forEach((weight, qty) {
        result[weight] = (result[weight] ?? 0) + qty;
      });
    }
    return result;
  }

  int get totalBottlesToLoad {
    try {
      return initialFullBottles.values.fold(0, (sum, q) => sum + q);
    } catch (_) {
      return 0;
    }
  }

  Map<int, int> get emptyBottlesLoaded => initialEmptyBottles;

  DateTime? get loadingCompletedDate => tourDate; // Par défaut pour la cohérence
  
  double get loadingFeePerBottle => 0.0;
  double get unloadingFeePerBottle => 0.0;
  
  double get totalLoadingFees => 0.0;
  double get totalUnloadingFees => 0.0;
  double get totalExchangeFees => 0.0;
  double get additionalInvoiceFees => 0.0;

  List<dynamic> get posDistributions => const []; // Migré/Obsolète
  List<dynamic> get loadingSources => const []; // Migré/Obsolète

  double get totalCashCollectedFromSites {
    return siteInteractions.fold(0.0, (sum, record) => sum + record.cashCollected);
  }

  int get totalFullBottlesDelivered {
    try {
      int total = 0;
      for (final record in siteInteractions) {
        total += record.fullBottlesDelivered.values.fold(0, (s, q) => s + q);
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  int get totalEmptyBottlesCollected {
    try {
      int total = 0;
      for (final record in siteInteractions) {
        total += record.emptyBottlesCollected.values.fold(0, (s, q) => s + q);
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  double get totalTransportExpenses {
    return transportExpenses.fold(0.0, (sum, e) => sum + e.amount);
  }

  double get totalGasPurchaseCost => gasPurchaseCost ?? 0.0;
}
