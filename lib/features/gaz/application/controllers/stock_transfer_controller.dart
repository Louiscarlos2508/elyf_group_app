import '../../domain/entities/stock_transfer.dart';
import '../../domain/repositories/stock_transfer_repository.dart';
import '../../domain/services/stock_transfer_service.dart';

class StockTransferController {
  const StockTransferController(this.repository, this.service);

  final StockTransferRepository repository;
  final StockTransferService service;

  Future<List<StockTransfer>> getTransfers(String enterpriseId) =>
      repository.getTransfers(enterpriseId);

  Stream<List<StockTransfer>> watchTransfers(String enterpriseId) =>
      repository.watchTransfers(enterpriseId);

  Future<StockTransfer?> getTransferById(String id) =>
      repository.getTransferById(id);

  Future<void> initiateTransfer(StockTransfer transfer) =>
      service.initiateTransfer(transfer);

  Future<void> shipTransfer(String id, String userId) =>
      service.shipTransfer(id, userId);

  Future<void> receiveTransfer(String id, String userId) =>
      service.receiveTransfer(id, userId);

  Future<void> cancelTransfer(String id, String userId) =>
      service.cancelTransfer(id, userId);
}
