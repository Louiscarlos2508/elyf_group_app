import '../../domain/repositories/enterprise_repository.dart';
import '../../domain/entities/enterprise.dart';

/// Implémentation mock du repository d'entreprises
class MockEnterpriseRepository implements EnterpriseRepository {
  final List<Enterprise> _enterprises = [
    Enterprise(
      id: 'eau_sachet_1',
      name: 'ELYF Eau Minérale - Siège',
      type: 'eau_minerale',
      description: 'Production et vente d\'eau en sachet',
      address: 'Bamako, Mali',
      phone: '+223 XX XX XX XX',
      email: 'eau1@elyf.ml',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      updatedAt: DateTime.now(),
    ),
    Enterprise(
      id: 'eau_sachet_2',
      name: 'ELYF Eau Minérale - Succursale',
      type: 'eau_minerale',
      description: 'Production et vente d\'eau en sachet',
      address: 'Koulikoro, Mali',
      phone: '+223 XX XX XX XX',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 180)),
      updatedAt: DateTime.now(),
    ),
    Enterprise(
      id: 'boutique_1',
      name: 'ELYF Boutique - Centre-ville',
      type: 'boutique',
      description: 'Vente physique et gestion de stock',
      address: 'Bamako, Mali',
      phone: '+223 XX XX XX XX',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 200)),
      updatedAt: DateTime.now(),
    ),
    Enterprise(
      id: 'immobilier_1',
      name: 'ELYF Immobilier',
      type: 'immobilier',
      description: 'Gestion de locations de maisons',
      address: 'Bamako, Mali',
      phone: '+223 XX XX XX XX',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 150)),
      updatedAt: DateTime.now(),
    ),
    Enterprise(
      id: 'gaz_1',
      name: 'ELYF Gaz',
      type: 'gaz',
      description: 'Distribution de bouteilles de gaz',
      address: 'Bamako, Mali',
      phone: '+223 XX XX XX XX',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 100)),
      updatedAt: DateTime.now(),
    ),
    Enterprise(
      id: 'orange_money_1',
      name: 'ELYF Orange Money',
      type: 'orange_money',
      description: 'Agent mobile Orange Money',
      address: 'Bamako, Mali',
      phone: '+223 XX XX XX XX',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 80)),
      updatedAt: DateTime.now(),
    ),
  ];

  @override
  Future<List<Enterprise>> getAllEnterprises() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_enterprises);
  }

  @override
  Future<List<Enterprise>> getEnterprisesByType(String type) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _enterprises.where((e) => e.type == type).toList();
  }

  @override
  Future<Enterprise?> getEnterpriseById(String enterpriseId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _enterprises.firstWhere((e) => e.id == enterpriseId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> createEnterprise(Enterprise enterprise) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _enterprises.add(enterprise);
  }

  @override
  Future<void> updateEnterprise(Enterprise enterprise) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _enterprises.indexWhere((e) => e.id == enterprise.id);
    if (index != -1) {
      _enterprises[index] = enterprise.copyWith(
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> deleteEnterprise(String enterpriseId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _enterprises.removeWhere((e) => e.id == enterpriseId);
  }

  @override
  Future<void> toggleEnterpriseStatus(
    String enterpriseId,
    bool isActive,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _enterprises.indexWhere((e) => e.id == enterpriseId);
    if (index != -1) {
      _enterprises[index] = _enterprises[index].copyWith(
        isActive: isActive,
        updatedAt: DateTime.now(),
      );
    }
  }
}

