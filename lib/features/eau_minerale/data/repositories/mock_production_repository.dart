import 'dart:async';

import '../../domain/entities/production.dart';
import '../../domain/entities/production_period_config.dart';
import '../../domain/repositories/production_repository.dart';

class MockProductionRepository implements ProductionRepository {
  final _productions = <String, Production>{};
  ProductionPeriodConfig _config = const ProductionPeriodConfig(daysPerPeriod: 10);

  MockProductionRepository() {
    // Initialize with sample data
    final now = DateTime.now();
    for (var i = 0; i < 8; i++) {
      final date = now.subtract(Duration(days: i));
      _productions['prod-$i'] = Production(
        id: 'prod-$i',
        date: date,
        quantity: 148 - (i * 10),
        period: _config.getPeriodForDate(date),
        rawMaterialsUsed: [
          RawMaterialUsage(
            productId: 'sachet-1',
            productName: 'Sachets',
            quantity: 70 + (i * 5),
            unit: 'unité',
          ),
        ],
        notes: 'Production session ${i + 1}',
      );
    }
  }

  @override
  Future<List<Production>> fetchProductions({
    DateTime? startDate,
    DateTime? endDate,
    int? period,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    var results = _productions.values.toList();

    if (startDate != null) {
      results = results.where((p) => p.date.isAfter(startDate)).toList();
    }
    if (endDate != null) {
      results = results.where((p) => p.date.isBefore(endDate)).toList();
    }
    if (period != null) {
      results = results.where((p) => p.period == period).toList();
    }

    results.sort((a, b) => b.date.compareTo(a.date));
    return results;
  }

  @override
  Future<Production?> getProduction(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _productions[id];
  }

  @override
  Future<String> createProduction(Production production) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final id = 'prod-${_productions.length}';
    _productions[id] = Production(
      id: id,
      date: production.date,
      quantity: production.quantity,
      period: production.period,
      rawMaterialsUsed: production.rawMaterialsUsed,
      notes: production.notes,
    );
    return id;
  }

  @override
  Future<int> getMonthProduction(DateTime month) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0);
    final productionsList = await fetchProductions(startDate: start, endDate: end);
    return productionsList.fold<int>(0, (sum, p) => sum + p.quantity);
  }

  @override
  Future<double> getAverageProduction() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final productions = _productions.values.toList();
    if (productions.isEmpty) return 0;
    final total = productions.fold(0, (sum, p) => sum + p.quantity);
    return total / productions.length;
  }

  @override
  Future<ProductionPeriodConfig> getPeriodConfig() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return _config;
  }

  @override
  Future<void> updatePeriodConfig(ProductionPeriodConfig config) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    _config = config;
  }
}
