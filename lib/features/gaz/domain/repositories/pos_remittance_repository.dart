import '../entities/pos_remittance.dart';

abstract class GazPOSRemittanceRepository {
  Future<List<GazPOSRemittance>> getRemittances(
    String enterpriseId, {
    String? posId,
    RemittanceStatus? status,
    DateTime? from,
    DateTime? to,
  });

  Stream<List<GazPOSRemittance>> watchRemittances(
    String enterpriseId, {
    String? posId,
    RemittanceStatus? status,
    DateTime? from,
    DateTime? to,
  });

  Future<GazPOSRemittance?> getRemittanceById(String id);
  Future<String> createRemittance(GazPOSRemittance remittance);
  Future<void> updateRemittance(GazPOSRemittance remittance);
  Future<void> updateStatus(String id, RemittanceStatus status, {String? validatedBy});
  Future<void> deleteRemittance(String id);
}
