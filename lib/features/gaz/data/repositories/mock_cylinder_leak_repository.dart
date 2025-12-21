import 'dart:math';
import '../../domain/entities/cylinder_leak.dart';
import '../../domain/repositories/cylinder_leak_repository.dart';

/// Implémentation mock du repository des bouteilles avec fuites.
class MockCylinderLeakRepository implements CylinderLeakRepository {
  final List<CylinderLeak> _leaks = [];
  final Random _random = Random();

  @override
  Future<List<CylinderLeak>> getLeaks(
    String enterpriseId, {
    LeakStatus? status,
  }) async {
    return _leaks.where((l) {
      // Note: On suppose que l'enterpriseId est dans cylinderId ou stocké séparément
      // Pour simplifier en mock, on retourne tous les leaks filtrés par status
      if (status != null && l.status != status) return false;
      return true;
    }).toList();
  }

  @override
  Future<CylinderLeak?> getLeakById(String id) async {
    return _leaks.where((l) => l.id == id).firstOrNull;
  }

  @override
  Future<String> reportLeak(CylinderLeak leak) async {
    final id = leak.id.isEmpty
        ? 'leak_${_random.nextInt(1000000)}'
        : leak.id;
    final newLeak = leak.copyWith(id: id);
    _leaks.add(newLeak);
    return id;
  }

  @override
  Future<void> updateLeak(CylinderLeak leak) async {
    final index = _leaks.indexWhere((l) => l.id == leak.id);
    if (index != -1) {
      _leaks[index] = leak;
    }
  }

  @override
  Future<void> markAsSentForExchange(String leakId) async {
    final index = _leaks.indexWhere((l) => l.id == leakId);
    if (index != -1) {
      _leaks[index] = _leaks[index].copyWith(
        status: LeakStatus.sentForExchange,
      );
    }
  }

  @override
  Future<void> markAsExchanged(
    String leakId,
    DateTime exchangeDate,
  ) async {
    final index = _leaks.indexWhere((l) => l.id == leakId);
    if (index != -1) {
      _leaks[index] = _leaks[index].copyWith(
        status: LeakStatus.exchanged,
        exchangeDate: exchangeDate,
      );
    }
  }

  @override
  Future<void> deleteLeak(String id) async {
    _leaks.removeWhere((l) => l.id == id);
  }
}