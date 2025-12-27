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
    this.collectionCompletedDate,
    this.transportCompletedDate,
    this.returnCompletedDate,
    this.closureDate,
    this.cancelledDate,
    this.notes,
  });

  final String id;
  final String enterpriseId;
  final DateTime tourDate;
  final TourStatus status;
  final List<Collection> collections;
  final double loadingFeePerBottle;
  final double unloadingFeePerBottle;
  final List<TransportExpense> transportExpenses;
  final DateTime? collectionCompletedDate;
  final DateTime? transportCompletedDate;
  final DateTime? returnCompletedDate;
  final DateTime? closureDate;
  final DateTime? cancelledDate;
  final String? notes;

  Tour copyWith({
    String? id,
    String? enterpriseId,
    DateTime? tourDate,
    TourStatus? status,
    List<Collection>? collections,
    double? loadingFeePerBottle,
    double? unloadingFeePerBottle,
    List<TransportExpense>? transportExpenses,
    DateTime? collectionCompletedDate,
    DateTime? transportCompletedDate,
    DateTime? returnCompletedDate,
    DateTime? closureDate,
    DateTime? cancelledDate,
    String? notes,
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
      collectionCompletedDate:
          collectionCompletedDate ?? this.collectionCompletedDate,
      transportCompletedDate:
          transportCompletedDate ?? this.transportCompletedDate,
      returnCompletedDate: returnCompletedDate ?? this.returnCompletedDate,
      closureDate: closureDate ?? this.closureDate,
      cancelledDate: cancelledDate ?? this.cancelledDate,
      notes: notes ?? this.notes,
    );
  }

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

