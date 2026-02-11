import '../../../../core/errors/app_exceptions.dart';
import '../../domain/entities/liquidity_checkpoint.dart';
import '../../domain/repositories/liquidity_repository.dart';
import '../../domain/services/liquidity_checkpoint_service.dart';
import '../../../audit_trail/domain/services/audit_trail_service.dart';
import '../../../../core/logging/app_logger.dart';

/// Controller for managing liquidity checkpoints.
class LiquidityController {
  LiquidityController(this._repository, this._auditTrailService, this.userId);

  final LiquidityRepository _repository;
  final AuditTrailService _auditTrailService;
  final String userId;

  Future<List<LiquidityCheckpoint>> fetchCheckpoints({
    String? enterpriseId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _repository.fetchCheckpoints(
      enterpriseId: enterpriseId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<LiquidityCheckpoint?> getCheckpoint(String checkpointId) async {
    return await _repository.getCheckpoint(checkpointId);
  }

  Future<LiquidityCheckpoint?> getTodayCheckpoint(String enterpriseId) async {
    return await _repository.getTodayCheckpoint(enterpriseId);
  }

  /// Crée un pointage de liquidité à partir des données du formulaire.
  Future<String> createCheckpointFromInput({
    required String? existingId,
    required String enterpriseId,
    required DateTime date,
    required LiquidityCheckpointType period,
    required int cashAmount,
    required int simAmount,
    String? notes,
    LiquidityCheckpoint? existingCheckpoint,
  }) async {
    // Valider les montants
    final validationError = LiquidityCheckpointService.validateAtLeastOneAmount(
      cashAmount,
      simAmount,
    );
    if (validationError != null) {
      throw ValidationException(
        validationError,
        'LIQUIDITY_VALIDATION_FAILED',
      );
    }

    // Créer le checkpoint via le service
    final checkpoint = LiquidityCheckpointService.createCheckpointFromInput(
      existingId: existingId,
      enterpriseId: enterpriseId,
      date: date,
      period: period,
      cashAmount: cashAmount,
      simAmount: simAmount,
      notes: notes,
      existingCheckpoint: existingCheckpoint,
    );

    if (existingCheckpoint != null) {
      await _repository.updateCheckpoint(checkpoint);
    } else {
      await _repository.createCheckpoint(checkpoint);
    }

    // Log to Audit Trail
    try {
      await _auditTrailService.logAction(
        enterpriseId: enterpriseId,
        userId: userId,
        module: 'orange_money',
        action: existingCheckpoint != null
            ? 'UPDATE_LIQUIDITY_CHECKPOINT'
            : 'CREATE_LIQUIDITY_CHECKPOINT',
        entityId: checkpoint.id,
        entityType: 'liquidity_checkpoint',
        metadata: {
          'period': period.name,
          'total': cashAmount + simAmount,
        },
      );
    } catch (e) {
      AppLogger.error('Failed to log liquidity checkpoint audit', error: e);
    }

    return checkpoint.id;
  }

  Future<String> createCheckpoint(LiquidityCheckpoint checkpoint) async {
    return await _repository.createCheckpoint(checkpoint);
  }

  Future<void> updateCheckpoint(LiquidityCheckpoint checkpoint) async {
    return await _repository.updateCheckpoint(checkpoint);
  }

  Future<void> deleteCheckpoint(String checkpointId) async {
    return await _repository.deleteCheckpoint(checkpointId, userId);
  }

  Future<void> restoreCheckpoint(String checkpointId) async {
    return await _repository.restoreCheckpoint(checkpointId);
  }

  Stream<List<LiquidityCheckpoint>> watchCheckpoints({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _repository.watchCheckpoints(
      startDate: startDate,
      endDate: endDate,
    );
  }

  Stream<List<LiquidityCheckpoint>> watchDeletedCheckpoints() {
    return _repository.watchDeletedCheckpoints();
  }

  Future<Map<String, dynamic>> getStatistics({
    String? enterpriseId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _repository.getStatistics(
      enterpriseId: enterpriseId,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
