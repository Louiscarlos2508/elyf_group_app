import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/production_session.dart';
import '../../domain/entities/production_session_status.dart';
import '../../domain/repositories/production_session_repository.dart';
import '../../../audit_trail/domain/services/audit_trail_service.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/services/machine_material_cost_service.dart';
import '../../domain/services/machine_stock_management_service.dart';
import 'stock_controller.dart';

class ProductionSessionController {
  ProductionSessionController(
    this._repository,
    this._stockController,
    this._productRepository,
    this._auditTrailService,
    this._costCalculatorService,
    this._stockManagementService,
  );

  final ProductionSessionRepository _repository;
  final StockController _stockController;
  final ProductRepository _productRepository;
  final AuditTrailService _auditTrailService;
  final MachineMaterialCostService _costCalculatorService;
  final MachineStockManagementService _stockManagementService;

  Future<List<ProductionSession>> fetchSessions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _repository.fetchSessions(startDate: startDate, endDate: endDate);
  }

  Stream<List<ProductionSession>> watchSessions({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _repository.watchSessions(startDate: startDate, endDate: endDate);
  }

  Future<ProductionSession?> fetchSessionById(String id) async {
    return _repository.fetchSessionById(id);
  }

  /// Crée une session et gère le stock pour les nouveaux matériaux installés.
  Future<ProductionSession> createSession(ProductionSession session) async {
    // Calculer le coût des matières installées (uniquement les nouvelles)
    final machineMaterialCost = await _costCalculatorService.calculateNewMaterialsCost(
      materials: session.machineMaterials,
      sessionId: session.id,
      isNewSession: true,
      existingSession: null,
    );

    final sessionAvecCout = session.copyWith(
      machineMaterialCost: session.machineMaterialCost ?? machineMaterialCost,
    );

    final savedSession = await _repository.createSession(sessionAvecCout);

    // Audit Log
    try {
      await _auditTrailService.logAction(
        enterpriseId: savedSession.enterpriseId,
        userId: savedSession.createdBy ?? 'unknown',
        module: 'eau_minerale',
        action: 'create_production_session',
        entityId: savedSession.id,
        entityType: 'production_session',
        metadata: {
          'status': savedSession.status.name,
          'date': savedSession.date.toIso8601String(),
        },
      );
    } catch (e) {
      AppLogger.error('Failed to log production session audit', error: e);
    }

    // Décrémenter le stock pour les matières nouvelles installées
    await _stockManagementService.decrementerStockMatieresNouvelles(
      matieresUtilisees: savedSession.machineMaterials,
      sessionId: savedSession.id,
      estNouvelleSession: true,
      sessionExistante: null,
    );

    return savedSession;
  }

  /// Met à jour une session et gère le stock.
  Future<ProductionSession> updateSession(ProductionSession session) async {
    final sessionExistante = await _repository.fetchSessionById(session.id);

    final machineMaterialCost = await _costCalculatorService.calculateNewMaterialsCost(
      materials: session.machineMaterials,
      sessionId: session.id,
      isNewSession: false,
      existingSession: sessionExistante,
    );

    final sessionAvecCout = session.copyWith(
      machineMaterialCost: session.machineMaterialCost ?? machineMaterialCost,
    );

    final savedSession = await _repository.updateSession(sessionAvecCout);

    // Finalisation : L'enregistrement des produits finis dans le stock
    // est désormais géré au niveau des enregistrements journaliers (Daily Logs)
    // dans personnel_stock_helper.dart pour éviter les doublons.
    if (savedSession.status == ProductionSessionStatus.completed &&
        sessionExistante?.status != ProductionSessionStatus.completed) {
      try {
        await _auditTrailService.logAction(
          enterpriseId: savedSession.enterpriseId,
          userId: savedSession.updatedBy ?? savedSession.createdBy ?? 'unknown',
          module: 'eau_minerale',
          action: 'finalize_production_session',
          entityId: savedSession.id,
          entityType: 'production_session',
        );
      } catch (e) {
        AppLogger.error('Failed to log session finalization audit', error: e);
      }
    }

    // Gérer le stock des matières installées
    await _stockManagementService.decrementerStockMatieresNouvelles(
      matieresUtilisees: savedSession.machineMaterials,
      sessionId: savedSession.id,
      estNouvelleSession: false,
      sessionExistante: sessionExistante,
    );

    return savedSession;
  }

  Future<void> deleteSession(String id) async {
    return _repository.deleteSession(id);
  }

  Future<void> cancelSession(ProductionSession session, String reason) async {
    final cancelledSession = session.copyWith(
      status: ProductionSessionStatus.cancelled,
      cancelReason: reason,
      updatedAt: DateTime.now(),
    );
    await _repository.updateSession(cancelledSession);
  }
}
