import '../entities/cylinder_leak.dart';

/// Interface pour le repository des bouteilles avec fuites.
abstract class CylinderLeakRepository {
  Future<List<CylinderLeak>> getLeaks(
    String enterpriseId, {
    LeakStatus? status,
  });

  Stream<List<CylinderLeak>> watchLeaks(
    String enterpriseId, {
    LeakStatus? status,
  });

  Future<CylinderLeak?> getLeakById(String id);

  Future<String> reportLeak(CylinderLeak leak);

  Future<void> updateLeak(CylinderLeak leak);

  Future<void> markAsSentForExchange(String leakId);

  Future<void> markAsExchanged(String leakId, DateTime exchangeDate);

  Future<void> deleteLeak(String id);
}
