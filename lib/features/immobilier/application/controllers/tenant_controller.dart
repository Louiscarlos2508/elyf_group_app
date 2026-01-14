import '../../domain/entities/tenant.dart';
import '../../domain/repositories/tenant_repository.dart';
import '../../domain/services/immobilier_validation_service.dart';

class TenantController {
  TenantController(this._tenantRepository, this._validationService);

  final TenantRepository _tenantRepository;
  final ImmobilierValidationService _validationService;

  Future<List<Tenant>> fetchTenants() async {
    return await _tenantRepository.getAllTenants();
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
    return await _tenantRepository.createTenant(tenant);
  }

  Future<Tenant> updateTenant(Tenant tenant) async {
    return await _tenantRepository.updateTenant(tenant);
  }

  /// Supprime un locataire après validation.
  Future<void> deleteTenant(String id) async {
    // Valider la suppression
    final validationError = await _validationService.validateTenantDeletion(id);
    if (validationError != null) {
      throw Exception(validationError);
    }

    await _tenantRepository.deleteTenant(id);
  }
}
