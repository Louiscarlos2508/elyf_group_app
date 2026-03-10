import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:elyf_groupe_app/features/gaz/domain/services/transaction_service.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/tour.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/cylinder.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/cylinder_stock.dart';
import 'package:elyf_groupe_app/features/gaz/domain/repositories/gas_repository.dart';
import 'package:elyf_groupe_app/features/gaz/domain/repositories/cylinder_stock_repository.dart';
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
  MockSpec<GazTreasuryRepository>(),
])
import 'transaction_service_test.mocks.dart';

void main() {
  late TransactionService service;
  late MockCylinderStockRepository mockStockRepo;
  late MockGasRepository mockGasRepo;
  late MockGazTreasuryRepository mockTreasuryRepo;
  late MockTourRepository mockTourRepo;
  late MockAuditTrailRepository mockAuditRepo;
  late MockGasAlertService mockAlertService;
  late MockDataConsistencyService mockConsistencyService;

  setUp(() {
    mockStockRepo = MockCylinderStockRepository();
    mockGasRepo = MockGasRepository();
    mockTreasuryRepo = MockGazTreasuryRepository();
    mockConsistencyService = MockDataConsistencyService();
    mockTourRepo = MockTourRepository();
    mockAuditRepo = MockAuditTrailRepository();
    mockAlertService = MockGasAlertService();

    service = TransactionService(
      stockRepository: mockStockRepo,
      gasRepository: mockGasRepo,
      tourRepository: mockTourRepo,
      consistencyService: mockConsistencyService,
      auditTrailRepository: mockAuditRepo,
      alertService: mockAlertService,
      leakRepository: MockCylinderLeakRepository(),
      exchangeRepository: MockExchangeRepository(),
      settingsRepository: MockGazSettingsRepository(),
      inventoryAuditRepository: MockGazInventoryAuditRepository(),
      expenseRepository: MockGazExpenseRepository(),
      treasuryRepository: mockTreasuryRepo,
    );
  });

  group('Tour Transactions (Manual Workflow)', () {
    const tourId = 'tour1';
    const userId = 'user1';
    const entId = 'ent1';

    // executeTourLoadingTransaction is obsolete (migrated to executeTourStartTransaction)

    test('executeTourClosureTransaction closes tour without moving stock', () async {
      // Arrange
      final tour = Tour(
        id: tourId,
        enterpriseId: entId,
        supplierName: 'SODIGAZ',
        tourDate: DateTime.now(),
        status: TourStatus.open,
        fullBottlesReceived: {12: 10},
      );

      when(mockTourRepo.getTourById(tourId)).thenAnswer((_) async => tour);

      // Act
      final result = await service.executeTourClosureTransaction(
        tourId: tourId,
        userId: userId,
        remainingFull: {12: 5},
        remainingEmpty: {12: 5},
      );

      // Assert
      expect(result.tour.status, TourStatus.closed);
      verify(mockTourRepo.updateTour(argThat(
        predicate<Tour>((Tour t) => t.status == TourStatus.closed)
      ))).called(1);

      // Verify NO stock movement
      verifyNever(mockStockRepo.addStock(any));
      verifyNever(mockStockRepo.deleteStock(any));
      verifyNever(mockStockRepo.updateStockQuantity(any, any));
    });

    test('executeTourCancellationTransaction cancels tour without reverting stock', () async {
      // Arrange
      final tour = Tour(
        id: tourId,
        enterpriseId: entId,
        supplierName: 'SODIGAZ',
        tourDate: DateTime.now(),
        status: TourStatus.open,
      );

      when(mockTourRepo.getTourById(tourId)).thenAnswer((_) async => tour);

      // Act
      await service.executeTourCancellationTransaction(
        tourId: tourId,
        userId: userId,
      );

      // Assert
      verify(mockTourRepo.updateTour(argThat(
        predicate<Tour>((Tour t) => t.status == TourStatus.cancelled)
      ))).called(1);

      // Verify NO stock movement
      verifyNever(mockStockRepo.addStock(any));
      verifyNever(mockStockRepo.deleteStock(any));
    });
  });
}
