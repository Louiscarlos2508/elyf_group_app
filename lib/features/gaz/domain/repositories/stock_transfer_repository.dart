import '../entities/stock_transfer.dart';

abstract class StockTransferRepository {
  Future<List<StockTransfer>> getTransfers(String enterpriseId);
  Stream<List<StockTransfer>> watchTransfers(String enterpriseId);
  Future<StockTransfer?> getTransferById(String id);
  Future<void> saveTransfer(StockTransfer transfer);
  Future<void> deleteTransfer(String id);
}
