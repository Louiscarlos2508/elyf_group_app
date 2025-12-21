import 'dart:math';
import '../../domain/entities/site_reconciliation.dart';
import '../../domain/repositories/site_reconciliation_repository.dart';

/// Implémentation mock du repository des réconciliations de sites.
class MockSiteReconciliationRepository
    implements SiteReconciliationRepository {
  final List<SiteReconciliation> _reconciliations = [];
  final Random _random = Random();

  @override
  Future<List<SiteReconciliation>> getReconciliationsBySite(
    String enterpriseId,
    String siteId,
  ) async {
    return _reconciliations.where((r) {
      return r.enterpriseId == enterpriseId && r.siteId == siteId;
    }).toList();
  }

  @override
  Future<SiteReconciliation?> getReconciliationById(String id) async {
    return _reconciliations.where((r) => r.id == id).firstOrNull;
  }

  @override
  Future<String> createReconciliation(
    SiteReconciliation reconciliation,
  ) async {
    final id = reconciliation.id.isEmpty
        ? 'reconciliation_${_random.nextInt(1000000)}'
        : reconciliation.id;
    final newReconciliation = reconciliation.copyWith(id: id);
    _reconciliations.add(newReconciliation);
    return id;
  }

  @override
  Future<void> updateReconciliation(
    SiteReconciliation reconciliation,
  ) async {
    final index =
        _reconciliations.indexWhere((r) => r.id == reconciliation.id);
    if (index != -1) {
      _reconciliations[index] = reconciliation;
    }
  }

  @override
  Future<void> updateReconciliationStatus(
    String id,
    ReconciliationStatus status,
  ) async {
    final index = _reconciliations.indexWhere((r) => r.id == id);
    if (index != -1) {
      _reconciliations[index] =
          _reconciliations[index].copyWith(status: status);
    }
  }

  @override
  Future<void> setPaymentProofUrl(String id, String imageUrl) async {
    final index = _reconciliations.indexWhere((r) => r.id == id);
    if (index != -1) {
      _reconciliations[index] = _reconciliations[index].copyWith(
        paymentProofScreenshot: imageUrl,
      );
    }
  }

  @override
  Future<void> deleteReconciliation(String id) async {
    _reconciliations.removeWhere((r) => r.id == id);
  }
}