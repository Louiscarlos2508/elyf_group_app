import 'collection.dart';
import 'transport_expense.dart';

/// Statut d'un tour d'approvisionnement.
enum TourStatus {
  collection('Collecte'),
  transport('Transport'),
  return_('Retour'),
  closure('Clôture'),
  cancelled('Annulé');

  const TourStatus(this.label);
  final String label;
}

/// Représente un tour d'approvisionnement complet.
class Tour {
  const Tour({
    required this.id,
    required this.enterpriseId,
    required this.tourDate,
    required this.status,
    required this.collections,
    required this.loadingFeePerBottle,
    required this.unloadingFeePerBottle,
    this.transportExpenses = const [],
    this.fullBottlesReceived = const {},
    this.gasPurchaseCost,
    this.collectionCompletedDate,
    this.transportCompletedDate,
    this.receptionCompletedDate,
    this.returnCompletedDate,
    this.closureDate,
    this.cancelledDate,
    this.notes,
    this.updatedAt,
    this.createdAt,
    this.deletedAt,
    this.deletedBy,
  });

  final String id;
  final String enterpriseId;
  final DateTime tourDate;
  final TourStatus status;
  final List<Collection> collections;
  final double loadingFeePerBottle;
  final double unloadingFeePerBottle;
  final List<TransportExpense> transportExpenses;
  final Map<int, int> fullBottlesReceived; // poids -> quantité
  final double? gasPurchaseCost;
  final DateTime? collectionCompletedDate;
  final DateTime? transportCompletedDate;
  final DateTime? receptionCompletedDate;
  final DateTime? returnCompletedDate;
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
    List<Collection>? collections,
    double? loadingFeePerBottle,
    double? unloadingFeePerBottle,
    List<TransportExpense>? transportExpenses,
    Map<int, int>? fullBottlesReceived,
    double? gasPurchaseCost,
    DateTime? collectionCompletedDate,
    DateTime? transportCompletedDate,
    DateTime? receptionCompletedDate,
    DateTime? returnCompletedDate,
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
      collections: collections ?? this.collections,
      loadingFeePerBottle: loadingFeePerBottle ?? this.loadingFeePerBottle,
      unloadingFeePerBottle:
          unloadingFeePerBottle ?? this.unloadingFeePerBottle,
      transportExpenses: transportExpenses ?? this.transportExpenses,
      fullBottlesReceived: fullBottlesReceived ?? this.fullBottlesReceived,
      gasPurchaseCost: gasPurchaseCost ?? this.gasPurchaseCost,
      collectionCompletedDate:
          collectionCompletedDate ?? this.collectionCompletedDate,
      transportCompletedDate:
          transportCompletedDate ?? this.transportCompletedDate,
      receptionCompletedDate:
          receptionCompletedDate ?? this.receptionCompletedDate,
      returnCompletedDate: returnCompletedDate ?? this.returnCompletedDate,
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
    // Utiliser localId en priorité car c'est l'ID réellement utilisé dans la base de données
    // Si localId n'existe pas, utiliser id comme fallback
    final tourId = map['localId'] as String? ?? map['id'] as String? ?? '';

    return Tour(
      id: tourId,
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      tourDate: DateTime.parse(map['tourDate'] as String),
      status: TourStatus.values.byName(map['status'] as String? ?? 'collection'),
      collections: (map['collections'] as List<dynamic>?)
              ?.map((c) => Collection.fromMap(c as Map<String, dynamic>))
              .toList() ??
          [],
      loadingFeePerBottle: (map['loadingFeePerBottle'] as num?)?.toDouble() ?? 0.0,
      unloadingFeePerBottle:
          (map['unloadingFeePerBottle'] as num?)?.toDouble() ?? 0.0,
      transportExpenses: (map['transportExpenses'] as List<dynamic>?)
              ?.map((e) => TransportExpense.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      fullBottlesReceived: (map['fullBottlesReceived'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(int.parse(k), (v as num).toInt()),
          ) ??
          {},
      gasPurchaseCost: (map['gasPurchaseCost'] as num?)?.toDouble(),
      collectionCompletedDate: map['collectionCompletedDate'] != null
          ? DateTime.parse(map['collectionCompletedDate'] as String)
          : null,
      transportCompletedDate: map['transportCompletedDate'] != null
          ? DateTime.parse(map['transportCompletedDate'] as String)
          : null,
      receptionCompletedDate: map['receptionCompletedDate'] != null
          ? DateTime.parse(map['receptionCompletedDate'] as String)
          : null,
      returnCompletedDate: map['returnCompletedDate'] != null
          ? DateTime.parse(map['returnCompletedDate'] as String)
          : null,
      closureDate: map['closureDate'] != null
          ? DateTime.parse(map['closureDate'] as String)
          : null,
      cancelledDate: map['cancelledDate'] != null
          ? DateTime.parse(map['cancelledDate'] as String)
          : null,
      notes: map['notes'] as String?,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      deletedAt: map['deletedAt'] != null
          ? DateTime.parse(map['deletedAt'] as String)
          : null,
      deletedBy: map['deletedBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'tourDate': tourDate.toIso8601String(),
      'status': status.name,
      'collections': collections.map((c) => c.toMap()).toList(),
      'loadingFeePerBottle': loadingFeePerBottle,
      'unloadingFeePerBottle': unloadingFeePerBottle,
      'transportExpenses': transportExpenses.map((e) => e.toMap()).toList(),
      'fullBottlesReceived': fullBottlesReceived.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'gasPurchaseCost': gasPurchaseCost,
      'collectionCompletedDate': collectionCompletedDate?.toIso8601String(),
      'transportCompletedDate': transportCompletedDate?.toIso8601String(),
      'receptionCompletedDate': receptionCompletedDate?.toIso8601String(),
      'returnCompletedDate': returnCompletedDate?.toIso8601String(),
      'closureDate': closureDate?.toIso8601String(),
      'cancelledDate': cancelledDate?.toIso8601String(),
      'notes': notes,
      'updatedAt': updatedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
    };
  }

  bool get isDeleted => deletedAt != null;

  /// Calcule le total des bouteilles à charger.
  int get totalBottlesToLoad {
    return collections.fold<int>(
      0,
      (sum, collection) => sum + collection.totalBottles,
    );
  }

  /// Calcule le total des frais de chargement.
  double get totalLoadingFees {
    return totalBottlesToLoad * loadingFeePerBottle;
  }

  /// Calcule le total des frais de déchargement.
  double get totalUnloadingFees {
    return totalBottlesToLoad * unloadingFeePerBottle;
  }

  /// Calcule le total des frais de transport.
  double get totalTransportExpenses {
    return transportExpenses.fold<double>(
      0.0,
      (sum, expense) => sum + expense.amount,
    );
  }

  /// Calcule le total encaissé (somme des paiements des collectes).
  double get totalCollected {
    return collections.fold<double>(
      0.0,
      (sum, collection) => sum + collection.amountPaid,
    );
  }

  /// Calcule le total des dépenses (transport + chargement + déchargement).
  double get totalExpenses {
    return totalTransportExpenses + totalLoadingFees + totalUnloadingFees;
  }

  /// Calcule le bénéfice net.
  double get netProfit {
    return totalCollected - totalExpenses;
  }

  /// Vérifie si toutes les collectes sont payées.
  bool get areAllCollectionsPaid {
    return collections.every((collection) => collection.isPaymentComplete);
  }
}
