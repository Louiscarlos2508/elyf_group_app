import '../entities/tenant.dart';

/// Repository abstrait pour la gestion des locataires.
abstract class TenantRepository {
  /// Récupère tous les locataires.
  Future<List<Tenant>> getAllTenants();

  /// Récupère un locataire par son ID.
  Future<Tenant?> getTenantById(String id);

  /// Recherche des locataires par nom ou téléphone.
  Future<List<Tenant>> searchTenants(String query);

  /// Crée un nouveau locataire.
  Future<Tenant> createTenant(Tenant tenant);

  /// Met à jour un locataire existant.
  Future<Tenant> updateTenant(Tenant tenant);

  /// Observe les locataires.
  Stream<List<Tenant>> watchTenants();

  /// Supprime un locataire.
  Future<void> deleteTenant(String id);
}
