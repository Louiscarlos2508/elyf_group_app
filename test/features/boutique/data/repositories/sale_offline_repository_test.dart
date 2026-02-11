import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elyf_groupe_app/features/boutique/data/repositories/sale_offline_repository.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/sale.dart';
import 'package:elyf_groupe_app/core/offline/connectivity_service.dart';
import 'package:elyf_groupe_app/core/offline/drift_service.dart';
import 'package:elyf_groupe_app/core/offline/sync_manager.dart';

void main() {
  group('SaleOfflineRepository', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('getSalesInPeriod filters sales correctly', () async {
      // Define test dates
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 12, 0);
      final yesterday = today.subtract(const Duration(days: 1));
      final tomorrow = today.add(const Duration(days: 1));

      // Define test data
      final saleYesterday = Sale(
        id: '1',
        enterpriseId: 'test-enterprise',
        date: yesterday,
        items: [],
        totalAmount: 1000,
        amountPaid: 1000,
      );
      final saleToday = Sale(
        id: '2',
        enterpriseId: 'test-enterprise',
        date: today,
        items: [],
        totalAmount: 2000,
        amountPaid: 2000,
      );
      final saleTomorrow = Sale(
        id: '3',
        enterpriseId: 'test-enterprise',
        date: tomorrow,
        items: [],
        totalAmount: 3000,
        amountPaid: 3000,
      );

      // Create a testable subclass that overrides getAllForEnterprise
      final testRepository = TestSaleOfflineRepository(
        mockSales: [saleYesterday, saleToday, saleTomorrow],
      );

      // Test period: Today only
      // Start of today to end of today
      final start = DateTime(now.year, now.month, now.day);
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final result = await testRepository.getSalesInPeriod(start, end);

      expect(result.length, 1);
      expect(result.first.id, '2');
      expect(result.first.totalAmount, 2000);
    });
  });
}

// Subclass to mock the data retrieval part without needing complex Drift mocking
class TestSaleOfflineRepository extends SaleOfflineRepository {
  final List<Sale> mockSales;

  TestSaleOfflineRepository({required this.mockSales})
      : super(
          driftService: MockDriftService(),
          syncManager: MockSyncManager(),
          connectivityService: MockConnectivityService(),
          enterpriseId: 'test-enterprise',
          moduleType: 'boutique',
        );

  @override
  Future<List<Sale>> getAllForEnterprise(String enterpriseId) async {
    return mockSales;
  }
}

// Mocks needed for super constructor
class MockDriftService extends Mock implements DriftService {}
class MockSyncManager extends Mock implements SyncManager {}
class MockConnectivityService extends Mock implements ConnectivityService {}

