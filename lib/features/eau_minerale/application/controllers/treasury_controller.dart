import '../../domain/repositories/treasury_repository.dart';
import '../../../../shared/domain/entities/treasury_operation.dart';

class TreasuryController {
  final TreasuryRepository _repository;
  final String _enterpriseId;
  final String _userId;

  TreasuryController(this._repository, this._enterpriseId, this._userId);

  Future<List<TreasuryOperation>> getOperations() async {
    return _repository.fetchOperations();
  }

  Stream<List<TreasuryOperation>> watchOperations() {
    return _repository.watchOperations();
  }

  Future<Map<String, int>> getBalances() async {
    return _repository.getBalances();
  }

  Stream<Map<String, int>> watchBalances() {
    return _repository.watchBalances();
  }

  Future<String> createOperation(TreasuryOperation operation) async {
    final entity = operation.copyWith(
      enterpriseId: _enterpriseId,
      userId: _userId,
    );
    return _repository.createOperation(entity);
  }
}
