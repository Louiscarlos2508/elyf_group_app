import '../entities/contract.dart';

/// Repository abstrait pour la gestion des contrats.
abstract class ContractRepository {
  /// Récupère tous les contrats.
  Future<List<Contract>> getAllContracts();

  /// Récupère un contrat par son ID.
  Future<Contract?> getContractById(String id);

  /// Récupère les contrats actifs.
  Future<List<Contract>> getActiveContracts();

  /// Récupère les contrats par propriété.
  Future<List<Contract>> getContractsByProperty(String propertyId);

  /// Récupère les contrats par locataire.
  Future<List<Contract>> getContractsByTenant(String tenantId);

  /// Crée un nouveau contrat.
  Future<Contract> createContract(Contract contract);

  /// Met à jour un contrat existant.
  Future<Contract> updateContract(Contract contract);

  /// Observe les contrats.
  Stream<List<Contract>> watchContracts();

  /// Supprime un contrat.
  Future<void> deleteContract(String id);
}
