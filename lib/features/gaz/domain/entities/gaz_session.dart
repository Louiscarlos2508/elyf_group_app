import '../services/gaz_calculation_service.dart';

class GazSession {
  const GazSession({
    required this.id,
    required this.enterpriseId,
    required this.status,
    required this.openedAt,
    required this.openedBy,
    this.date,
    this.theoreticalCash = 0,
    this.physicalCash = 0,
    this.discrepancy = 0,
    this.closedBy,
    this.closedAt,
    this.notes,
    this.isSynced = false,
    this.totalSales = 0,
    this.totalExpenses = 0,
    this.stockReconciliation = const {},
    this.theoreticalStock = const {},
    this.theoreticalEmptyStock = const {},
    this.emptyStockReconciliation = const {},
    this.openingFullStock = const {},
    this.openingEmptyStock = const {},
    this.openingCash = 0.0,
  });

  final String id;
  final String enterpriseId;
  final GazSessionStatus status;
  final DateTime openedAt;
  final String openedBy;
  final DateTime? date; // Date comptable (souvent openedAt.date)
  final double theoreticalCash;
  final double physicalCash;
  final double discrepancy;
  final String? closedBy;
  final DateTime? closedAt;
  final String? notes;
  final bool isSynced;
  final double totalSales;
  final double totalExpenses;
  final Map<int, int> stockReconciliation;
  final Map<int, int> theoreticalStock;
  final Map<int, int> theoreticalEmptyStock;
  final Map<int, int> emptyStockReconciliation;
  final Map<int, int> openingFullStock;
  final Map<int, int> openingEmptyStock;
  final double openingCash;

  bool get isOpen => status == GazSessionStatus.open;
  bool get isClosed => status == GazSessionStatus.closed;

  bool get hasDiscrepancy => discrepancy != 0 || stockReconciliation.values.any((v) => v != 0);

  factory GazSession.fromMetrics({
    required String id,
    required String enterpriseId,
    required ReconciliationMetrics metrics,
    required double physicalCash,
    required String closedBy,
    Map<int, int> physicalStock = const {},
    Map<int, int> physicalEmptyStock = const {},
    Map<int, int> openingFullStock = const {},
    Map<int, int> openingEmptyStock = const {},
    double openingCash = 0.0,
    String? notes,
  }) {
    final theoretical = metrics.theoreticalCash;
    final stockReconciliation = <int, int>{};
    for (final weight in metrics.salesByCylinderWeight.keys) {
      final theoreticalQty = metrics.theoreticalStock[weight] ?? 0;
      final physicalQty = physicalStock[weight] ?? theoreticalQty;
      stockReconciliation[weight] = physicalQty - theoreticalQty;
    }

    // New: Calculate Empty Stock Reconciliation
    final emptyStockReconciliation = <int, int>{};
    for (final weight in metrics.theoreticalEmptyStock.keys) {
      final theoreticalQty = metrics.theoreticalEmptyStock[weight] ?? 0;
      final physicalQty = physicalEmptyStock[weight] ?? theoreticalQty;
      emptyStockReconciliation[weight] = physicalQty - theoreticalQty;
    }


    return GazSession(
      id: id,
      enterpriseId: enterpriseId,
      status: GazSessionStatus.closed,
      openedAt: metrics.date, // On suppose que le début de la metrics est l'ouverture
      openedBy: closedBy, // Temporaire, à raffiner si on a l'info
      date: metrics.date,
      theoreticalCash: theoretical,
      physicalCash: physicalCash,
      discrepancy: physicalCash - theoretical,
      closedBy: closedBy,
      closedAt: DateTime.now(),
      notes: notes,
      totalSales: metrics.totalSales,
      totalExpenses: metrics.totalExpenses,
      stockReconciliation: stockReconciliation,
      theoreticalStock: metrics.theoreticalStock,
      theoreticalEmptyStock: metrics.theoreticalEmptyStock,
      emptyStockReconciliation: emptyStockReconciliation,
      openingFullStock: openingFullStock,
      openingEmptyStock: openingEmptyStock,
      openingCash: openingCash,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'status': status.name,
      'openedAt': openedAt.toIso8601String(),
      'openedBy': openedBy,
      'date': date?.toIso8601String(),
      'theoreticalCash': theoreticalCash,
      'physicalCash': physicalCash,
      'discrepancy': discrepancy,
      'closedBy': closedBy,
      'closedAt': closedAt?.toIso8601String(),
      'notes': notes,
      'totalSales': totalSales,
      'totalExpenses': totalExpenses,
      'stockReconciliation': stockReconciliation.map((k, v) => MapEntry(k.toString(), v)),
      'theoreticalStock': theoreticalStock.map((k, v) => MapEntry(k.toString(), v)),
      'theoreticalEmptyStock': theoreticalEmptyStock.map((k, v) => MapEntry(k.toString(), v)),
      'emptyStockReconciliation': emptyStockReconciliation.map((k, v) => MapEntry(k.toString(), v)),
      'openingFullStock': openingFullStock.map((k, v) => MapEntry(k.toString(), v)),
      'openingEmptyStock': openingEmptyStock.map((k, v) => MapEntry(k.toString(), v)),
      'openingCash': openingCash,
    };
  }

  factory GazSession.fromMap(Map<String, dynamic> map) {
    return GazSession(
      id: map['id'] as String,
      enterpriseId: map['enterpriseId'] as String,
      status: GazSessionStatus.values.byName(map['status'] as String? ?? 'closed'),
      openedAt: DateTime.parse(map['openedAt'] as String? ?? map['date'] as String),
      openedBy: map['openedBy'] as String? ?? map['closedBy'] as String? ?? '',
      date: map['date'] != null ? DateTime.parse(map['date'] as String) : null,
      theoreticalCash: (map['theoreticalCash'] as num?)?.toDouble() ?? 0.0,
      physicalCash: (map['physicalCash'] as num?)?.toDouble() ?? 0.0,
      discrepancy: (map['discrepancy'] as num?)?.toDouble() ?? 0.0,
      closedBy: map['closedBy'] as String?,
      closedAt: map['closedAt'] != null ? DateTime.parse(map['closedAt'] as String) : null,
      notes: map['notes'] as String?,
      totalSales: (map['totalSales'] as num?)?.toDouble() ?? 0,
      totalExpenses: (map['totalExpenses'] as num?)?.toDouble() ?? 0,
      stockReconciliation: (map['stockReconciliation'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(int.parse(k), v as int)) ??
          {},
      theoreticalStock: (map['theoreticalStock'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(int.parse(k), v as int)) ??
          {},
      theoreticalEmptyStock: (map['theoreticalEmptyStock'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(int.parse(k), v as int)) ??
          {},
      emptyStockReconciliation: (map['emptyStockReconciliation'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(int.parse(k), v as int)) ??
          {},
      openingFullStock: (map['openingFullStock'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(int.parse(k), v as int)) ??
          {},
      openingEmptyStock: (map['openingEmptyStock'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(int.parse(k), v as int)) ??
          {},
      openingCash: (map['openingCash'] as num?)?.toDouble() ?? 0.0,
    );
  }

  GazSession copyWith({
    String? id,
    String? enterpriseId,
    GazSessionStatus? status,
    DateTime? openedAt,
    String? openedBy,
    DateTime? date,
    double? theoreticalCash,
    double? physicalCash,
    double? discrepancy,
    String? closedBy,
    DateTime? closedAt,
    String? notes,
    bool? isSynced,
    double? totalSales,
    double? totalExpenses,
    Map<int, int>? stockReconciliation,
    Map<int, int>? theoreticalStock,
    Map<int, int>? theoreticalEmptyStock,
    Map<int, int>? emptyStockReconciliation,
    Map<int, int>? openingFullStock,
    Map<int, int>? openingEmptyStock,
    double? openingCash,
  }) {
    return GazSession(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      status: status ?? this.status,
      openedAt: openedAt ?? this.openedAt,
      openedBy: openedBy ?? this.openedBy,
      date: date ?? this.date,
      theoreticalCash: theoreticalCash ?? this.theoreticalCash,
      physicalCash: physicalCash ?? this.physicalCash,
      discrepancy: discrepancy ?? this.discrepancy,
      closedBy: closedBy ?? this.closedBy,
      closedAt: closedAt ?? this.closedAt,
      notes: notes ?? this.notes,
      isSynced: isSynced ?? this.isSynced,
      totalSales: totalSales ?? this.totalSales,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      stockReconciliation: stockReconciliation ?? this.stockReconciliation,
      theoreticalStock: theoreticalStock ?? this.theoreticalStock,
      theoreticalEmptyStock: theoreticalEmptyStock ?? this.theoreticalEmptyStock,
      emptyStockReconciliation: emptyStockReconciliation ?? this.emptyStockReconciliation,
      openingFullStock: openingFullStock ?? this.openingFullStock,
      openingEmptyStock: openingEmptyStock ?? this.openingEmptyStock,
      openingCash: openingCash ?? this.openingCash,
    );
  }
}

enum GazSessionStatus { open, closed }
