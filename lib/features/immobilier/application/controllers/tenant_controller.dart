import '../../../audit_trail/domain/services/audit_trail_service.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../domain/entities/tenant.dart';
import '../../domain/repositories/tenant_repository.dart';
import '../../domain/services/immobilier_validation_service.dart';

class TenantController {
  TenantController(
    this._tenantRepository,
    this._validationService,
    this._auditTrailService,
    this._enterpriseId,
    this._userId,
  );

  final TenantRepository _tenantRepository;
  final ImmobilierValidationService _validationService;
  final AuditTrailService _auditTrailService;
  final String _enterpriseId;
  final String _userId;

  Future<List<Tenant>> fetchTenants() async {
    return await _tenantRepository.getAllTenants();
  }

  Stream<List<Tenant>> watchTenants({bool? isDeleted = false}) {
    return _tenantRepository.watchTenants(isDeleted: isDeleted);
  }

  Stream<List<Tenant>> watchDeletedTenants() {
    return _tenantRepository.watchTenants(isDeleted: true);
  }

  Future<Tenant?> getTenant(String id) async {
    return await _tenantRepository.getTenantById(id);
  }

  Future<List<Tenant>> searchTenants(String query) async {
    if (query.isEmpty) {
      return await fetchTenants();
    }
    return await _tenantRepository.searchTenants(query);
  }

  Future<Tenant> createTenant(Tenant tenant) async {
    final created = await _tenantRepository.createTenant(tenant);
    await _logAction('create', created.id, metadata: created.toMap());
    return created;
  }

  Future<Tenant> updateTenant(Tenant tenant) async {
    final updated = await _tenantRepository.updateTenant(tenant);
    await _logAction('update', updated.id, metadata: updated.toMap());
    return updated;
  }

  /// Supprime un locataire après validation.
  Future<void> deleteTenant(String id) async {
    // Valider la suppression
    final validationError = await _validationService.validateTenantDeletion(id);
    if (validationError != null) {
      throw ValidationException(
        validationError,
        'TENANT_DELETION_VALIDATION_FAILED',
      );
    }

    await _tenantRepository.deleteTenant(id);
    await _logAction('delete', id);
  }

  Future<void> restoreTenant(String id) async {
    await _tenantRepository.restoreTenant(id);
    await _logAction('restore', id);
  }

  Future<void> _logAction(
    String action,
    String entityId, {
    Map<String, dynamic>? metadata,
  }) async {
    await _auditTrailService.logAction(
      enterpriseId: _enterpriseId,
      userId: _userId,
      module: 'immobilier',
      action: action,
      entityId: entityId,
      entityType: 'tenant',
      metadata: metadata,
    );
  }
}
