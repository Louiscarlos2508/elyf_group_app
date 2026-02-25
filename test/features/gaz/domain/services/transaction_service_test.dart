import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:elyf_groupe_app/features/gaz/domain/services/transaction_service.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/collection.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/cylinder.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/cylinder_stock.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/gas_sale.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/gaz_session.dart';
import 'package:elyf_groupe_app/features/gaz/domain/repositories/gas_repository.dart';
import 'package:elyf_groupe_app/features/gaz/domain/repositories/cylinder_stock_repository.dart';
import 'package:elyf_groupe_app/features/gaz/domain/repositories/session_repository.dart';
import 'package:elyf_groupe_app/features/gaz/domain/repositories/treasury_repository.dart';
import 'package:elyf_groupe_app/features/gaz/domain/repositories/tour_repository.dart';
import 'package:elyf_groupe_app/features/gaz/domain/services/data_consistency_service.dart';
import 'package:elyf_groupe_app/features/audit_trail/domain/repositories/audit_trail_repository.dart';
import 'package:elyf_groupe_app/features/gaz/domain/services/gas_alert_service.dart';
import 'package:elyf_groupe_app/features/gaz/domain/repositories/cylinder_leak_repository.dart';
import 'package:elyf_groupe_app/features/gaz/domain/repositories/exchange_repository.dart';
import 'package:elyf_groupe_app/features/gaz/domain/repositories/gaz_settings_repository.dart';
import 'package:elyf_groupe_app/features/gaz/domain/repositories/inventory_audit_repository.dart';
import 'package:elyf_groupe_app/features/gaz/domain/repositories/expense_repository.dart';
import 'package:elyf_groupe_app/features/gaz/domain/repositories/collection_repository.dart';
import 'package:elyf_groupe_app/shared/domain/entities/treasury_operation.dart';

@GenerateNiceMocks([
  MockSpec<CylinderStockRepository>(),
  MockSpec<GasRepository>(),
  MockSpec<TourRepository>(),
  MockSpec<DataConsistencyService>(),
  MockSpec<AuditTrailRepository>(),
  MockSpec<GasAlertService>(),
  MockSpec<CylinderLeakRepository>(),
  MockSpec<ExchangeRepository>(),
  MockSpec<GazSettingsRepository>(),
  MockSpec<GazInventoryAuditRepository>(),
  MockSpec<GazExpenseRepository>(),
  MockSpec<GazSessionRepository>(),
  MockSpec<GazTreasuryRepository>(),
  MockSpec<CollectionRepository>(),
])
import 'transaction_service_test.mocks.dart';

void main() {
  late TransactionService service;
  late MockCylinderStockRepository mockStockRepo;
  late MockGasRepository mockGasRepo;
  late MockGazSessionRepository mockSessionRepo;
  late MockGazTreasuryRepository mockTreasuryRepo;
  late MockCollectionRepository mockCollectionRepo;
  late MockDataConsistencyService mockConsistencyService; // Added mock for DataConsistencyService

  setUp(() {
    mockStockRepo = MockCylinderStockRepository();
    mockGasRepo = MockGasRepository();
    mockSessionRepo = MockGazSessionRepository();
    mockTreasuryRepo = MockGazTreasuryRepository();
    mockCollectionRepo = MockCollectionRepository();
    mockConsistencyService = MockDataConsistencyService(); // Initialize mock

    service = TransactionService(
      stockRepository: mockStockRepo,
      gasRepository: mockGasRepo,
      tourRepository: MockTourRepository(),
      consistencyService: mockConsistencyService, // Inject mock
      auditTrailRepository: MockAuditTrailRepository(),
      alertService: MockGasAlertService(),
      leakRepository: MockCylinderLeakRepository(),
      exchangeRepository: MockExchangeRepository(),
      settingsRepository: MockGazSettingsRepository(),
      inventoryAuditRepository: MockGazInventoryAuditRepository(),
      expenseRepository: MockGazExpenseRepository(),
      sessionRepository: mockSessionRepo,
      treasuryRepository: mockTreasuryRepo,
      collectionRepository: mockCollectionRepo,
    );
  });

  test('executeIndependentCollectionTransaction updates stock and treasury', () async {
    // Arrange
    final cylinder12kg = Cylinder(
      id: 'c12',
      weight: 12,
      buyPrice: 5000,
      sellPrice: 6000,
      enterpriseId: 'ent1',
      moduleId: 'gaz',
    );

    final collection = Collection(
      id: 'col1',
      type: CollectionType.wholesaler,
      clientId: 'w1',
      clientName: 'Wholesaler 1',
      clientPhone: '12345678',
      emptyBottles: {12: 10},
      unitPrice: 0,
      amountPaid: 5000, // We pay 5000 FCFA for return
      paymentDate: DateTime.now(),
    );

    // Mocks behavior
    when(mockSessionRepo.getActiveSession('ent1')).thenAnswer((_) async => GazSession(
      id: 'sess1',
      enterpriseId: 'ent1',
      status: GazSessionStatus.open,
      openedAt: DateTime.now(),
      openedBy: 'user1',
      date: DateTime.now(),
      theoreticalCash: 0,
      physicalCash: 0,
      discrepancy: 0,
      theoreticalStock: {},
      theoreticalEmptyStock: {},
      totalExpenses: 0,
      totalSales: 0,
    ));

    when(mockGasRepo.getCylinders()).thenAnswer((_) async => [cylinder12kg]);
    
    // Mock stock retrieval for sale transaction
    when(mockStockRepo.getStocksByWeight(any, any, siteId: anyNamed('siteId'))).thenAnswer((_) async => []);

    // Mock validation success
     when(mockConsistencyService.validateSaleConsistency(
      sale: anyNamed('sale'),
      enterpriseId: anyNamed('enterpriseId'),
      siteId: anyNamed('siteId'),
      weight: anyNamed('weight'),
    )).thenAnswer((_) async => null);

    // Act
    await service.executeIndependentCollectionTransaction(
      collection: collection,
      enterpriseId: 'ent1',
      userId: 'user1',
    );

    // Assert
    // 1. Check stock update (Empty stock created/updated)
    verify(mockStockRepo.addStock(argThat(
      predicate<CylinderStock>((s) => s.status == CylinderStatus.emptyAtStore && s.quantity == 10 && s.weight == 12)
    ))).called(1);

    // 2. Check Collection saving
    verify(mockCollectionRepo.saveCollection(argThat(
      predicate<Collection>((c) => c.id == 'col1' && c.emptyBottles[12] == 10)
    ), 'ent1')).called(1);

    // 3. Check Treasury update (Expense)
    verify(mockTreasuryRepo.saveOperation(argThat(
      predicate<TreasuryOperation>((t) => t.amount == 5000 && t.type == TreasuryOperationType.removal)
    ))).called(1);
  });
}
