import '../entities/site_logistics_record.dart';

abstract class GazSiteLogisticsRecordRepository {
  Future<List<GazSiteLogisticsRecord>> getRecords(String enterpriseId);
  Stream<List<GazSiteLogisticsRecord>> watchRecords(String enterpriseId);
  Future<GazSiteLogisticsRecord?> getRecordBySiteId(String enterpriseId, String siteId);
  Future<void> saveRecord(GazSiteLogisticsRecord record);
  Stream<GazSiteLogisticsRecord?> watchRecordBySiteId(String enterpriseId, String siteId);
}
