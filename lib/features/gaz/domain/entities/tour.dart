import 'package:elyf_groupe_app/features/gaz/domain/entities/transport_expense.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';

export 'transport_expense.dart';

/// Type de source pour le chargement.
enum TourLoadingSourceType {
  pos('Point de vente'),
  wholesaler('Grossiste');

  const TourLoadingSourceType(this.label);
  final String label;
}

/// Représente une source de chargement de bouteilles vides.
class TourLoadingSource {
  const TourLoadingSource({
    required this.id,
    required this.type,
    required this.sourceName,
    required this.quantities,
  });

  final String id;
  final TourLoadingSourceType type;
  final String sourceName;
  final Map<int, int> quantities;

  factory TourLoadingSource.fromMap(Map<String, dynamic> map) {
    return TourLoadingSource(
      id: map['id'] as String? ?? '',
      type: TourLoadingSourceType.values.byName(map['type'] as String? ?? 'pos'),
      sourceName: map['sourceName'] as String? ?? '',
      quantities: (map['quantities'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(int.parse(k), (v as num).toInt()),
          ) ??
          const <int, int>{},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'sourceName': sourceName,
      'quantities': quantities.map((k, v) => MapEntry(k.toString(), v)),
    };
  }

  TourLoadingSource copyWith({
    String? id,
    TourLoadingSourceType? type,
    String? sourceName,
    Map<int, int>? quantities,
  }) {
    return TourLoadingSource(
      id: id ?? this.id,
      type: type ?? this.type,
      sourceName: sourceName ?? this.sourceName,
      quantities: quantities ?? this.quantities,
    );
  }
}

/// Représente une distribution/vente à un grossiste lors de la clôture.
class WholesaleDistribution {
  const WholesaleDistribution({
    required this.wholesalerId,
    required this.wholesalerName,
    required this.quantities,
    required this.totalAmount,
    this.paymentMethod = PaymentMethod.cash,
  });

  final String wholesalerId;
  final String wholesalerName;
  final Map<int, int> quantities;
  final double totalAmount;
  final PaymentMethod paymentMethod;

  Map<String, dynamic> toMap() {
    return {
      'wholesalerId': wholesalerId,
      'wholesalerName': wholesalerName,
      'quantities': quantities.map((k, v) => MapEntry(k.toString(), v)),
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod.name,
    };
  }
}

/// Représente une distribution à un point de vente lors du tour.
class PosDistribution {
  const PosDistribution({
    required this.posId,
    required this.posName,
    required this.quantities,
    this.receivedDate,
  });

  final String posId;
  final String posName;
  final Map<int, int> quantities;
  final DateTime? receivedDate;

  Map<String, dynamic> toMap() {
    return {
      'posId': posId,
      'posName': posName,
      'quantities': quantities.map((k, v) => MapEntry(k.toString(), v)),
      'receivedDate': receivedDate?.toIso8601String(),
    };
  }

  factory PosDistribution.fromMap(Map<String, dynamic> map) {
    return PosDistribution(
      posId: map['posId'] as String? ?? '',
      posName: map['posName'] as String? ?? '',
      quantities: (map['quantities'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(int.parse(k), (v as num).toInt()),
          ) ??
          const <int, int>{},
      receivedDate: map['receivedDate'] != null ? DateTime.parse(map['receivedDate'] as String) : null,
    );
  }
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
    @Deprecated('Frais logistiques inclus dans le prix d\'achat')
    this.loadingFeePerBottle = 0.0,
    @Deprecated('Frais logistiques inclus dans le prix d\'achat')
    this.unloadingFeePerBottle = 0.0,
    @Deprecated('Frais logistiques inclus dans le prix d\'achat')
    Map<int, double>? loadingFees,
    @Deprecated('Frais logistiques inclus dans le prix d\'achat')
    Map<int, double>? unloadingFees,
    this.fixedUnloadingFee = 0.0,
    Map<int, double>? exchangeFees,
    Map<int, double>? purchasePricesUsed,
    @Deprecated('Utiliser loadingSources à la place')
    Map<int, int>? emptyBottlesLoaded,
    List<TourLoadingSource>? loadingSources,
    List<TransportExpense>? transportExpenses,
    Map<int, int>? fullBottlesReceived,
    Map<int, int>? emptyBottlesReturned,
    this.gasPurchaseCost,
    this.supplierName,
    this.loadingCompletedDate,
    this.transportCompletedDate,
    this.receptionCompletedDate,
    this.closureDate,
    this.cancelledDate,
    this.notes,
    List<WholesaleDistribution>? wholesaleDistributions,
    List<PosDistribution>? posDistributions,
    @Deprecated('Frais logistiques inclus dans le prix d\'achat')
    this.applyLoadingFees = true,
    this.sessionId,
    double? additionalInvoiceFees,
    this.updatedAt,
    this.createdAt,
    this.deletedAt,
    this.deletedBy,
  })  : _loadingFees = loadingFees,
        _unloadingFees = unloadingFees,
        _exchangeFees = exchangeFees,
        _purchasePricesUsed = purchasePricesUsed,
        _emptyBottlesLoaded = emptyBottlesLoaded,
        _loadingSources = loadingSources,
        _transportExpenses = transportExpenses,
        _fullBottlesReceived = fullBottlesReceived,
        _emptyBottlesReturned = emptyBottlesReturned,
        _wholesaleDistributions = wholesaleDistributions,
        _posDistributions = posDistributions,
        _additionalInvoiceFees = additionalInvoiceFees;

  final String id;
  final String enterpriseId;
  final DateTime tourDate;
  final TourStatus status;

  @Deprecated('Frais logistiques inclus dans le prix d\'achat')
  final double loadingFeePerBottle;
  @Deprecated('Frais logistiques inclus dans le prix d\'achat')
  final double unloadingFeePerBottle;

  final Map<int, double>? _loadingFees;
  @Deprecated('Frais logistiques inclus dans le prix d\'achat')
  Map<int, double> get loadingFees => _loadingFees ?? const <int, double>{};

  final Map<int, double>? _unloadingFees;
  @Deprecated('Frais logistiques inclus dans le prix d\'achat')
  Map<int, double> get unloadingFees => _unloadingFees ?? const <int, double>{};

  final double fixedUnloadingFee;

  final Map<int, double>? _exchangeFees;
  Map<int, double> get exchangeFees => _exchangeFees ?? const <int, double>{};

  final Map<int, double>? _purchasePricesUsed;
  Map<int, double> get purchasePricesUsed => _purchasePricesUsed ?? const <int, double>{};

  final Map<int, int>? _emptyBottlesLoaded;
  @Deprecated('Utiliser loadingSources à la place')
  Map<int, int> get emptyBottlesLoaded => _emptyBottlesLoaded ?? const <int, int>{};

  final List<TourLoadingSource>? _loadingSources;
  List<TourLoadingSource> get loadingSources => _loadingSources ?? const <TourLoadingSource>[];

  final List<WholesaleDistribution>? _wholesaleDistributions;
  List<WholesaleDistribution> get wholesaleDistributions => _wholesaleDistributions ?? const <WholesaleDistribution>[];

  final List<PosDistribution>? _posDistributions;
  List<PosDistribution> get posDistributions => _posDistributions ?? const <PosDistribution>[];

  final List<TransportExpense>? _transportExpenses;
  List<TransportExpense> get transportExpenses => _transportExpenses ?? const <TransportExpense>[];

  final Map<int, int>? _fullBottlesReceived;
  Map<int, int> get fullBottlesReceived => _fullBottlesReceived ?? const <int, int>{};

  final Map<int, int>? _emptyBottlesReturned;
  Map<int, int> get emptyBottlesReturned => _emptyBottlesReturned ?? const <int, int>{};

  final double? gasPurchaseCost;
  final String? supplierName;
  final DateTime? loadingCompletedDate;
  final DateTime? transportCompletedDate;
  final DateTime? receptionCompletedDate;
  final DateTime? closureDate;
  final DateTime? cancelledDate;
  final String? notes;

  @Deprecated('Frais logistiques inclus dans le prix d\'achat')
  final bool applyLoadingFees;
  final String? sessionId;
  final double? _additionalInvoiceFees;
  double get additionalInvoiceFees => _additionalInvoiceFees ?? 0.0;
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
    Map<int, double>? loadingFees,
    Map<int, double>? unloadingFees,
    double? fixedUnloadingFee,
    Map<int, double>? exchangeFees,
    Map<int, double>? purchasePricesUsed,
    Map<int, int>? emptyBottlesLoaded,
    List<TourLoadingSource>? loadingSources,
    List<TransportExpense>? transportExpenses,
    Map<int, int>? fullBottlesReceived,
    Map<int, int>? emptyBottlesReturned,
    double? gasPurchaseCost,
    String? supplierName,
    DateTime? loadingCompletedDate,
    DateTime? transportCompletedDate,
    DateTime? receptionCompletedDate,
    DateTime? closureDate,
    DateTime? cancelledDate,
    String? notes,
    bool? applyLoadingFees,
    String? sessionId,
    double? additionalInvoiceFees,
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
      loadingFees: loadingFees ?? _loadingFees,
      unloadingFees: unloadingFees ?? _unloadingFees,
      fixedUnloadingFee: fixedUnloadingFee ?? this.fixedUnloadingFee,
      exchangeFees: exchangeFees ?? _exchangeFees,
      purchasePricesUsed: purchasePricesUsed ?? _purchasePricesUsed,
      emptyBottlesLoaded: emptyBottlesLoaded ?? _emptyBottlesLoaded,
      loadingSources: loadingSources ?? _loadingSources,
      transportExpenses: transportExpenses ?? _transportExpenses,
      fullBottlesReceived: fullBottlesReceived ?? _fullBottlesReceived,
      emptyBottlesReturned: emptyBottlesReturned ?? _emptyBottlesReturned,
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
      applyLoadingFees: applyLoadingFees ?? this.applyLoadingFees,
      sessionId: sessionId ?? this.sessionId,
      additionalInvoiceFees: additionalInvoiceFees ?? _additionalInvoiceFees,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  factory Tour.fromMap(Map<String, dynamic> map, String defaultEnterpriseId) {
    // Prioritize embedded localId to maintain offline relations on new devices
    final validLocalId = map['localId'] as String?;
    final objectId = (validLocalId != null && validLocalId.trim().isNotEmpty)
        ? validLocalId
        : (map['id'] as String? ?? '');

    final statusStr = map['status'] as String? ?? 'loading';
    final migratedStatus = _migrateStatus(statusStr);

    return Tour(
      id: objectId,
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      tourDate: DateTime.parse(map['tourDate'] as String),
      status: migratedStatus,
      loadingFeePerBottle:
          (map['loadingFeePerBottle'] as num?)?.toDouble() ?? 0.0,
      unloadingFeePerBottle:
          (map['unloadingFeePerBottle'] as num?)?.toDouble() ?? 0.0,
      loadingFees: (map['loadingFees'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(int.parse(k), (v as num).toDouble()),
          ) ??
          const <int, double>{},
      unloadingFees: (map['unloadingFees'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(int.parse(k), (v as num).toDouble()),
          ) ??
          const <int, double>{},
      fixedUnloadingFee:
          (map['fixedUnloadingFee'] as num?)?.toDouble() ?? 0.0,
      exchangeFees: (map['exchangeFees'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(int.parse(k), (v as num).toDouble()),
          ) ??
          const <int, double>{},
      purchasePricesUsed: (map['purchasePricesUsed'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(int.parse(k), (v as num).toDouble()),
          ) ??
          const <int, double>{},
      emptyBottlesLoaded:
          (map['emptyBottlesLoaded'] as Map<String, dynamic>?)?.map(
                (k, v) => MapEntry(int.parse(k), (v as num).toInt()),
              ) ??
              const <int, int>{},
      loadingSources: (map['loadingSources'] as List<dynamic>?)
              ?.map((s) => TourLoadingSource.fromMap(s as Map<String, dynamic>))
              .toList() ??
          const [],
      transportExpenses: (map['transportExpenses'] as List<dynamic>?)
              ?.map(
                  (e) => TransportExpense.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      wholesaleDistributions: (map['wholesaleDistributions'] as List<dynamic>?)
              ?.map((e) => WholesaleDistribution.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      posDistributions: (map['posDistributions'] as List<dynamic>?)
              ?.map((e) => PosDistribution.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      fullBottlesReceived:
          (map['fullBottlesReceived'] as Map<String, dynamic>?)?.map(
                (k, v) => MapEntry(int.parse(k), (v as num).toInt()),
              ) ??
              const <int, int>{},
      emptyBottlesReturned:
          (map['emptyBottlesReturned'] as Map<String, dynamic>?)?.map(
                (k, v) => MapEntry(int.parse(k), (v as num).toInt()),
              ) ??
              const <int, int>{},
      gasPurchaseCost: (map['gasPurchaseCost'] as num?)?.toDouble(),
      supplierName: map['supplierName'] as String?,
      loadingCompletedDate: _parseDate(map['loadingCompletedDate'] ?? map['collectionCompletedDate']),
      transportCompletedDate: _parseDate(map['transportCompletedDate']),
      receptionCompletedDate: _parseDate(map['receptionCompletedDate'] ?? map['returnCompletedDate']),
      closureDate: _parseDate(map['closureDate']),
      cancelledDate: _parseDate(map['cancelledDate']),
      notes: map['notes'] as String?,
      applyLoadingFees: map['applyLoadingFees'] as bool? ?? true,
      sessionId: map['sessionId'] as String?,
      additionalInvoiceFees: (map['additionalInvoiceFees'] as num?)?.toDouble(),
      updatedAt: _parseDate(map['updatedAt']),
      createdAt: _parseDate(map['createdAt']),
      deletedAt: _parseDate(map['deletedAt']),
      deletedBy: map['deletedBy'] as String?,
    );
  }

  static TourStatus _migrateStatus(String status) {
    switch (status) {
      case 'loading':
      case 'transport':
      case 'reception':
        return TourStatus.open;
      case 'closure':
        return TourStatus.closed;
      case 'cancelled':
        return TourStatus.cancelled;
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
      'loadingFees': loadingFees.map((k, v) => MapEntry(k.toString(), v)),
      'unloadingFees': unloadingFees.map((k, v) => MapEntry(k.toString(), v)),
      'fixedUnloadingFee': fixedUnloadingFee,
      'exchangeFees': exchangeFees.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'purchasePricesUsed': purchasePricesUsed.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'emptyBottlesLoaded': emptyBottlesLoaded.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'loadingSources': loadingSources.map((TourLoadingSource s) => s.toMap()).toList(),
      'transportExpenses': transportExpenses.map((TransportExpense e) => e.toMap()).toList(),
      'fullBottlesReceived': fullBottlesReceived.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'emptyBottlesReturned': emptyBottlesReturned.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'wholesaleDistributions': wholesaleDistributions.map((WholesaleDistribution d) => d.toMap()).toList(),
      'posDistributions': posDistributions.map((PosDistribution d) => d.toMap()).toList(),
      'gasPurchaseCost': gasPurchaseCost,
      'supplierName': supplierName,
      'loadingCompletedDate': loadingCompletedDate?.toIso8601String(),
      'transportCompletedDate': transportCompletedDate?.toIso8601String(),
      'receptionCompletedDate': receptionCompletedDate?.toIso8601String(),
      'closureDate': closureDate?.toIso8601String(),
      'cancelledDate': cancelledDate?.toIso8601String(),
      'notes': notes,
      'applyLoadingFees': applyLoadingFees,
      'sessionId': sessionId,
      'additionalInvoiceFees': additionalInvoiceFees,
      'updatedAt': updatedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
    };
  }

  bool get isDeleted => deletedAt != null;

  int get totalBottlesToLoad {
    int total = 0;
    for (final source in loadingSources) {
      total += source.quantities.values.fold<int>(0, (sum, qty) => sum + qty);
    }
    return total;
  }

  int get totalBottlesReceived {
    return fullBottlesReceived.values.fold<int>(0, (sum, qty) => sum + qty);
  }

  int get totalBottlesReturned {
    return emptyBottlesReturned.values.fold<int>(0, (sum, qty) => sum + qty);
  }

  double get totalLoadingFees {
    double total = 0;
    for (final entry in emptyBottlesLoaded.entries) {
      total += entry.value * (loadingFees[entry.key] ?? 0.0);
    }
    return total;
  }

  double get totalUnloadingFees {
    double total = fixedUnloadingFee;
    for (final entry in fullBottlesReceived.entries) {
      total += entry.value * (unloadingFees[entry.key] ?? 0.0);
    }
    return total;
  }

  double get totalExchangeFees {
    double total = 0;
    for (final entry in fullBottlesReceived.entries) {
      total += entry.value * (exchangeFees[entry.key] ?? 0.0);
    }
    return total;
  }

  double get totalGasPurchaseCost => gasPurchaseCost ?? 0.0;

  double get totalTransportExpenses {
    return transportExpenses.fold<double>(
      0.0,
      (sum, expense) => sum + expense.amount,
    );
  }

  double get totalExpenses {
    return totalExchangeFees +
        totalGasPurchaseCost +
        totalTransportExpenses +
        additionalInvoiceFees;
  }
}

/// Statut d'un tour.
enum TourStatus {
  open('En cours'),
  closed('Clôturé'),
  cancelled('Annulé');

  const TourStatus(this.label);
  final String label;
}
