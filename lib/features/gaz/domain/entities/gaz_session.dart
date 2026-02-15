import '../services/gaz_calculation_service.dart';

/// Représente une clôture de session journalière pour le module Gaz.
class GazSession {
  const GazSession({
    required this.id,
    required this.enterpriseId,
    required this.date,
    required this.theoreticalCash,
    required this.physicalCash,
    required this.discrepancy,
    required this.closedBy,
    required this.closedAt,
    this.notes,
    this.isSynced = false,
    this.totalSales = 0,
    this.totalExpenses = 0,
  });

  final String id;
  final String enterpriseId;
  final DateTime date;
  final double theoreticalCash;
  final double physicalCash;
  final double discrepancy;
  final String closedBy;
  final DateTime closedAt;
  final String? notes;
  final bool isSynced;
  final double totalSales;
  final double totalExpenses;

  bool get hasDiscrepancy => discrepancy != 0;

  factory GazSession.fromMetrics({
    required String id,
    required String enterpriseId,
    required ReconciliationMetrics metrics,
    required double physicalCash,
    required String closedBy,
    String? notes,
  }) {
    final theoretical = metrics.theoreticalCash;
    return GazSession(
      id: id,
      enterpriseId: enterpriseId,
      date: metrics.date,
      theoreticalCash: theoretical,
      physicalCash: physicalCash,
      discrepancy: physicalCash - theoretical,
      closedBy: closedBy,
      closedAt: DateTime.now(),
      notes: notes,
      totalSales: metrics.totalSales,
      totalExpenses: metrics.totalExpenses,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'date': date.toIso8601String(),
      'theoreticalCash': theoreticalCash,
      'physicalCash': physicalCash,
      'discrepancy': discrepancy,
      'closedBy': closedBy,
      'closedAt': closedAt.toIso8601String(),
      'notes': notes,
      'totalSales': totalSales,
      'totalExpenses': totalExpenses,
    };
  }

  factory GazSession.fromMap(Map<String, dynamic> map) {
    return GazSession(
      id: map['id'] as String,
      enterpriseId: map['enterpriseId'] as String,
      date: DateTime.parse(map['date'] as String),
      theoreticalCash: (map['theoreticalCash'] as num).toDouble(),
      physicalCash: (map['physicalCash'] as num).toDouble(),
      discrepancy: (map['discrepancy'] as num).toDouble(),
      closedBy: map['closedBy'] as String,
      closedAt: DateTime.parse(map['closedAt'] as String),
      notes: map['notes'] as String?,
      totalSales: (map['totalSales'] as num?)?.toDouble() ?? 0,
      totalExpenses: (map['totalExpenses'] as num?)?.toDouble() ?? 0,
    );
  }
}
