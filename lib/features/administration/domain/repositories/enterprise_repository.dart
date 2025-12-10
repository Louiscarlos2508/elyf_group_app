import '../entities/enterprise.dart';

/// Repository pour la gestion des entreprises
abstract class EnterpriseRepository {
  /// Récupère toutes les entreprises
  Future<List<Enterprise>> getAllEnterprises();

  /// Récupère les entreprises par type
  Future<List<Enterprise>> getEnterprisesByType(String type);

  /// Récupère une entreprise par son ID
  Future<Enterprise?> getEnterpriseById(String enterpriseId);

  /// Crée une nouvelle entreprise
  Future<void> createEnterprise(Enterprise enterprise);

  /// Met à jour une entreprise
  Future<void> updateEnterprise(Enterprise enterprise);

  /// Supprime une entreprise
  Future<void> deleteEnterprise(String enterpriseId);

  /// Active/désactive une entreprise
  Future<void> toggleEnterpriseStatus(String enterpriseId, bool isActive);
}

