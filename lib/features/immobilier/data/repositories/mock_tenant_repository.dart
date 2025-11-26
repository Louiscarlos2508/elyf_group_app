import '../../domain/entities/tenant.dart';
import '../../domain/repositories/tenant_repository.dart';

class MockTenantRepository implements TenantRepository {
  final _tenants = <String, Tenant>{};

  MockTenantRepository() {
    _initMockData();
  }

  void _initMockData() {
    final tenants = [
      Tenant(
        id: 'tenant-1',
        fullName: 'Jean Kaboré',
        phone: '+226 70 12 34 56',
        email: 'jean.kabore@example.com',
        address: '123 Rue de la Paix, Ouagadougou',
        idNumber: 'CI-123456',
        emergencyContact: '+226 76 12 34 56',
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
      ),
      Tenant(
        id: 'tenant-2',
        fullName: 'Marie Ouédraogo',
        phone: '+226 70 23 45 67',
        email: 'marie.ouedraogo@example.com',
        address: '456 Avenue Kwame N\'Krumah',
        idNumber: 'CI-234567',
        createdAt: DateTime.now().subtract(const Duration(days: 120)),
      ),
      Tenant(
        id: 'tenant-3',
        fullName: 'Amadou Traoré',
        phone: '+226 70 34 56 78',
        email: 'amadou.traore@example.com',
        address: '789 Boulevard Charles de Gaulle',
        idNumber: 'CI-345678',
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
      ),
    ];

    for (final tenant in tenants) {
      _tenants[tenant.id] = tenant;
    }
  }

  @override
  Future<List<Tenant>> getAllTenants() async {
    return _tenants.values.toList();
  }

  @override
  Future<Tenant?> getTenantById(String id) async {
    return _tenants[id];
  }

  @override
  Future<List<Tenant>> searchTenants(String query) async {
    final lowerQuery = query.toLowerCase();
    return _tenants.values.where((tenant) {
      return tenant.fullName.toLowerCase().contains(lowerQuery) ||
          tenant.phone.contains(query) ||
          (tenant.email?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  @override
  Future<Tenant> createTenant(Tenant tenant) async {
    final now = DateTime.now();
    final newTenant = Tenant(
      id: tenant.id,
      fullName: tenant.fullName,
      phone: tenant.phone,
      email: tenant.email,
      address: tenant.address,
      idNumber: tenant.idNumber,
      emergencyContact: tenant.emergencyContact,
      notes: tenant.notes,
      createdAt: now,
      updatedAt: now,
    );
    _tenants[tenant.id] = newTenant;
    return newTenant;
  }

  @override
  Future<Tenant> updateTenant(Tenant tenant) async {
    final existing = _tenants[tenant.id];
    if (existing == null) {
      throw Exception('Tenant not found');
    }
    final updated = Tenant(
      id: tenant.id,
      fullName: tenant.fullName,
      phone: tenant.phone,
      email: tenant.email,
      address: tenant.address,
      idNumber: tenant.idNumber,
      emergencyContact: tenant.emergencyContact,
      notes: tenant.notes,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
    _tenants[tenant.id] = updated;
    return updated;
  }

  @override
  Future<void> deleteTenant(String id) async {
    _tenants.remove(id);
  }
}

