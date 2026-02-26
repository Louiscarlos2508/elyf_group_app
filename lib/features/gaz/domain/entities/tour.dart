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
    Map<int, double>? loadingFees,
    Map<int, double>? unloadingFees,
    this.fixedUnloadingFee = 0.0,
    Map<int, double>? exchangeFees,
    Map<int, double>? purchasePricesUsed,
    Map<int, int>? emptyBottlesLoaded,
    Map<int, int>? leakingBottlesLoaded,
    this.transportExpenses = const [],
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
    this.applyLoadingFees = true,
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
        _leakingBottlesLoaded = leakingBottlesLoaded,
        _fullBottlesReceived = fullBottlesReceived,
        _emptyBottlesReturned = emptyBottlesReturned,
        _additionalInvoiceFees = additionalInvoiceFees;

  final String id;
  final String enterpriseId;
  final DateTime tourDate;
  final TourStatus status;
  final double loadingFeePerBottle;
  final double unloadingFeePerBottle;

  final Map<int, double>? _loadingFees;
  Map<int, double> get loadingFees => _loadingFees ?? const <int, double>{};

  final Map<int, double>? _unloadingFees;
  Map<int, double> get unloadingFees => _unloadingFees ?? const <int, double>{};

  final double fixedUnloadingFee;

  final Map<int, double>? _exchangeFees;
  Map<int, double> get exchangeFees => _exchangeFees ?? const <int, double>{};

  final Map<int, double>? _purchasePricesUsed;
  Map<int, double> get purchasePricesUsed => _purchasePricesUsed ?? const <int, double>{};

  final Map<int, int>? _emptyBottlesLoaded;
  Map<int, int> get emptyBottlesLoaded => _emptyBottlesLoaded ?? const <int, int>{};

  final Map<int, int>? _leakingBottlesLoaded;
  Map<int, int> get leakingBottlesLoaded => _leakingBottlesLoaded ?? const <int, int>{};

  final List<TransportExpense> transportExpenses;

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
  final bool applyLoadingFees;
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
    Map<int, int>? leakingBottlesLoaded,
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
      leakingBottlesLoaded: leakingBottlesLoaded ?? _leakingBottlesLoaded,
      transportExpenses: transportExpenses ?? this.transportExpenses,
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
      additionalInvoiceFees: additionalInvoiceFees ?? _additionalInvoiceFees,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  factory Tour.fromMap(Map<String, dynamic> map, String defaultEnterpriseId) {
    final tourId = map['localId'] as String? ?? map['id'] as String? ?? '';

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
      leakingBottlesLoaded:
          (map['leakingBottlesLoaded'] as Map<String, dynamic>?)?.map(
                (k, v) => MapEntry(int.parse(k), (v as num).toInt()),
              ) ??
              const <int, int>{},
      transportExpenses: (map['transportExpenses'] as List<dynamic>?)
              ?.map(
                  (e) => TransportExpense.fromMap(e as Map<String, dynamic>))
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
      'leakingBottlesLoaded': leakingBottlesLoaded.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'transportExpenses': transportExpenses.map((e) => e.toMap()).toList(),
      'fullBottlesReceived': fullBottlesReceived.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'emptyBottlesReturned': emptyBottlesReturned.map(
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
      'applyLoadingFees': applyLoadingFees,
      'additionalInvoiceFees': additionalInvoiceFees,
      'updatedAt': updatedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
    };
  }

  bool get isDeleted => deletedAt != null;

  int get totalBottlesToLoad {
    final empty = emptyBottlesLoaded.values.fold<int>(0, (sum, qty) => sum + qty);
    final leaky = leakingBottlesLoaded.values.fold<int>(0, (sum, qty) => sum + qty);
    return empty + leaky;
  }

  int get totalBottlesReceived {
    return fullBottlesReceived.values.fold<int>(0, (sum, qty) => sum + qty);
  }

  int get totalBottlesReturned {
    return emptyBottlesReturned.values.fold<int>(0, (sum, qty) => sum + qty);
  }

  double get totalLoadingFees {
    if (!applyLoadingFees) return 0.0;
    if (loadingFees.isNotEmpty) {
      double total = 0.0;
      emptyBottlesLoaded.forEach((weight, qty) {
        total += qty * (loadingFees[weight] ?? loadingFeePerBottle);
      });
      return total;
    }
    return totalBottlesToLoad * loadingFeePerBottle;
  }

  double get totalUnloadingFees {
    double baseUnloading = 0.0;
    if (unloadingFees.isNotEmpty) {
      fullBottlesReceived.forEach((weight, qty) {
        baseUnloading += qty * (unloadingFees[weight] ?? unloadingFeePerBottle);
      });
    } else {
      baseUnloading = totalBottlesReceived * unloadingFeePerBottle;
    }
    return baseUnloading + fixedUnloadingFee;
  }

  double get totalExchangeFees {
    double total = 0.0;
    fullBottlesReceived.forEach((weight, qty) {
      final fee = exchangeFees[weight] ?? 0.0;
      total += qty * fee;
    });
    return total;
  }

  double get totalTransportExpenses {
    return transportExpenses.fold<double>(
      0.0,
      (sum, expense) => sum + expense.amount,
    );
  }

  double get totalGasPurchaseCost {
    // Prioritize the manually entered invoice total for overall costs
    return gasPurchaseCost ?? 0.0;
  }

  double get totalExpenses {
    return totalTransportExpenses +
        totalLoadingFees +
        totalUnloadingFees +
        totalExchangeFees +
        totalGasPurchaseCost +
        additionalInvoiceFees;
  }
}
