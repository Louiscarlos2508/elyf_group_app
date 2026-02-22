import 'transport_expense.dart';

/// Statut d'un tour d'approvisionnement (fournisseur uniquement).
enum TourStatus {
  open('En cours'),
  closed('Clôturé'),
  cancelled('Annulé');

  const TourStatus(this.label);
  final String label;
}

/// Représente un tour d'approvisionnement fournisseur.
///
/// Le tour gère uniquement l'échange de bouteilles avec le fournisseur :
/// charger les vides → transporter → recevoir les pleines → clôturer.
/// La collecte des vides depuis les POS est une opération indépendante.
class Tour {
  const Tour({
    required this.id,
    required this.enterpriseId,
    required this.tourDate,
    required this.status,
    this.loadingFeePerBottle = 0.0,
    this.unloadingFeePerBottle = 0.0,
    this.fixedUnloadingFee = 0.0,
    this.exchangeFees = const {},
    this.emptyBottlesLoaded = const {},
    this.transportExpenses = const [],
    this.fullBottlesReceived = const {},
    this.gasPurchaseCost,
    this.supplierName,
    this.loadingCompletedDate,
    this.transportCompletedDate,
    this.receptionCompletedDate,
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
  final double loadingFeePerBottle;
  final double unloadingFeePerBottle;
  final double fixedUnloadingFee;
  /// Frais d'échange par type de bouteille (poids -> prix)
  final Map<int, double> exchangeFees;
  /// Bouteilles vides chargées pour l'échange (poids → quantité)
  final Map<int, int> emptyBottlesLoaded;
  final List<TransportExpense> transportExpenses;
  /// Bouteilles pleines reçues du fournisseur (poids → quantité)
  final Map<int, int> fullBottlesReceived;
  final double? gasPurchaseCost;
  final String? supplierName;
  final DateTime? loadingCompletedDate;
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
    double? loadingFeePerBottle,
    double? unloadingFeePerBottle,
    double? fixedUnloadingFee,
    Map<int, double>? exchangeFees,
    Map<int, int>? emptyBottlesLoaded,
    List<TransportExpense>? transportExpenses,
    Map<int, int>? fullBottlesReceived,
    double? gasPurchaseCost,
    String? supplierName,
    DateTime? loadingCompletedDate,
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
      loadingFeePerBottle: loadingFeePerBottle ?? this.loadingFeePerBottle,
      unloadingFeePerBottle:
          unloadingFeePerBottle ?? this.unloadingFeePerBottle,
      fixedUnloadingFee: fixedUnloadingFee ?? this.fixedUnloadingFee,
      exchangeFees: exchangeFees ?? this.exchangeFees,
      emptyBottlesLoaded: emptyBottlesLoaded ?? this.emptyBottlesLoaded,
      transportExpenses: transportExpenses ?? this.transportExpenses,
      fullBottlesReceived: fullBottlesReceived ?? this.fullBottlesReceived,
      gasPurchaseCost: gasPurchaseCost ?? this.gasPurchaseCost,
      supplierName: supplierName ?? this.supplierName,
      loadingCompletedDate:
          loadingCompletedDate ?? this.loadingCompletedDate,
      transportCompletedDate:
          transportCompletedDate ?? this.transportCompletedDate,
      receptionCompletedDate:
          receptionCompletedDate ?? this.receptionCompletedDate,
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
    final tourId = map['localId'] as String? ?? map['id'] as String? ?? '';

    // Migration: lire l'ancien champ "status" avec les anciens noms
    final statusStr = map['status'] as String? ?? 'loading';
    final migratedStatus = _migrateStatus(statusStr);

    return Tour(
      id: tourId,
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      tourDate: DateTime.parse(map['tourDate'] as String),
      status: migratedStatus,
      loadingFeePerBottle:
          (map['loadingFeePerBottle'] as num?)?.toDouble() ?? 0.0,
      unloadingFeePerBottle:
          (map['unloadingFeePerBottle'] as num?)?.toDouble() ?? 0.0,
      fixedUnloadingFee:
          (map['fixedUnloadingFee'] as num?)?.toDouble() ?? 0.0,
      exchangeFees: (map['exchangeFees'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(int.parse(k), (v as num).toDouble()),
          ) ??
          {},
      emptyBottlesLoaded:
          (map['emptyBottlesLoaded'] as Map<String, dynamic>?)?.map(
                (k, v) => MapEntry(int.parse(k), (v as num).toInt()),
              ) ??
              {},
      transportExpenses: (map['transportExpenses'] as List<dynamic>?)
              ?.map(
                  (e) => TransportExpense.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      fullBottlesReceived:
          (map['fullBottlesReceived'] as Map<String, dynamic>?)?.map(
                (k, v) => MapEntry(int.parse(k), (v as num).toInt()),
              ) ??
              {},
      gasPurchaseCost: (map['gasPurchaseCost'] as num?)?.toDouble(),
      supplierName: map['supplierName'] as String?,
      loadingCompletedDate: _parseDate(map['loadingCompletedDate'] ?? map['collectionCompletedDate']),
      transportCompletedDate: _parseDate(map['transportCompletedDate']),
      receptionCompletedDate: _parseDate(map['receptionCompletedDate'] ?? map['returnCompletedDate']),
      closureDate: _parseDate(map['closureDate']),
      cancelledDate: _parseDate(map['cancelledDate']),
      notes: map['notes'] as String?,
      updatedAt: _parseDate(map['updatedAt']),
      createdAt: _parseDate(map['createdAt']),
      deletedAt: _parseDate(map['deletedAt']),
      deletedBy: map['deletedBy'] as String?,
    );
  }

  /// Migre les anciens noms de statut vers les nouveaux.
  static TourStatus _migrateStatus(String status) {
    switch (status) {
      case 'loading':
      case 'transport':
      case 'reception':
        return TourStatus.open;
      case 'closure':
        return TourStatus.closed;
      default:
        try {
          return TourStatus.values.byName(status);
        } catch (_) {
          return TourStatus.open;
        }
    }
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.parse(value as String);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'tourDate': tourDate.toIso8601String(),
      'status': status.name,
      'loadingFeePerBottle': loadingFeePerBottle,
      'unloadingFeePerBottle': unloadingFeePerBottle,
      'fixedUnloadingFee': fixedUnloadingFee,
      'exchangeFees': exchangeFees.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'emptyBottlesLoaded': emptyBottlesLoaded.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'transportExpenses': transportExpenses.map((e) => e.toMap()).toList(),
      'fullBottlesReceived': fullBottlesReceived.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'gasPurchaseCost': gasPurchaseCost,
      'supplierName': supplierName,
      'loadingCompletedDate': loadingCompletedDate?.toIso8601String(),
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

  bool get isDeleted => deletedAt != null;

  /// Total des bouteilles vides chargées.
  int get totalBottlesToLoad {
    return emptyBottlesLoaded.values.fold<int>(0, (sum, qty) => sum + qty);
  }

  /// Total des bouteilles pleines reçues.
  int get totalBottlesReceived {
    return fullBottlesReceived.values.fold<int>(0, (sum, qty) => sum + qty);
  }

  /// Calcule le total des frais de chargement.
  double get totalLoadingFees {
    return totalBottlesToLoad * loadingFeePerBottle;
  }

  /// Calcule le total des frais de déchargement.
  double get totalUnloadingFees {
    return (totalBottlesReceived * unloadingFeePerBottle) + fixedUnloadingFee;
  }

  /// Calcule le total des frais d'échange.
  double get totalExchangeFees {
    double total = 0.0;
    fullBottlesReceived.forEach((weight, qty) {
      final fee = exchangeFees[weight] ?? 0.0;
      total += qty * fee;
    });
    return total;
  }

  /// Calcule le total des frais de transport.
  double get totalTransportExpenses {
    return transportExpenses.fold<double>(
      0.0,
      (sum, expense) => sum + expense.amount,
    );
  }

  /// Calcule le total des dépenses (transport + chargement + déchargement + échange + achat gaz).
  double get totalExpenses {
    return totalTransportExpenses +
        totalLoadingFees +
        totalUnloadingFees +
        totalExchangeFees +
        (gasPurchaseCost ?? 0.0);
  }
}
