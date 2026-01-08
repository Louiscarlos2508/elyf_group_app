import '../../domain/entities/enterprise.dart';
import '../../domain/repositories/enterprise_repository.dart';

/// Controller pour gérer les entreprises.
class EnterpriseController {
  EnterpriseController(this._repository);

  final EnterpriseRepository _repository;

  /// Récupère toutes les entreprises.
  Future<List<Enterprise>> getAllEnterprises() async {
    return await _repository.getAllEnterprises();
  }

  /// Récupère les entreprises par type.
  Future<List<Enterprise>> getEnterprisesByType(String type) async {
    return await _repository.getEnterprisesByType(type);
  }

  /// Récupère une entreprise par son ID.
  Future<Enterprise?> getEnterpriseById(String enterpriseId) async {
    return await _repository.getEnterpriseById(enterpriseId);
  }

  /// Crée une nouvelle entreprise.
  Future<void> createEnterprise(Enterprise enterprise) async {
    return await _repository.createEnterprise(enterprise);
  }

  /// Met à jour une entreprise.
  Future<void> updateEnterprise(Enterprise enterprise) async {
    return await _repository.updateEnterprise(enterprise);
  }

  /// Supprime une entreprise.
  Future<void> deleteEnterprise(String enterpriseId) async {
    return await _repository.deleteEnterprise(enterpriseId);
  }

  /// Active ou désactive une entreprise.
  Future<void> toggleEnterpriseStatus(
    String enterpriseId,
    bool isActive,
  ) async {
    return await _repository.toggleEnterpriseStatus(enterpriseId, isActive);
  }
}

