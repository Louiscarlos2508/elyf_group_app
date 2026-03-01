import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:elyf_groupe_app/features/gaz/application/controllers/cylinder_stock_controller.dart';
import 'package:elyf_groupe_app/features/gaz/domain/repositories/cylinder_stock_repository.dart';
import 'package:elyf_groupe_app/features/gaz/domain/services/stock_service.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/cylinder_stock.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/cylinder.dart';
import '../../../../helpers/test_helpers.dart';

import 'cylinder_stock_controller_test.mocks.dart';

import 'package:elyf_groupe_app/features/gaz/domain/services/transaction_service.dart';

@GenerateMocks([CylinderStockRepository, StockService, TransactionService])
void main() {
  late CylinderStockController controller;
  late MockCylinderStockRepository mockRepository;
  late MockStockService mockStockService;
  late MockTransactionService mockTransactionService;

  setUp(() {
    mockRepository = MockCylinderStockRepository();
    mockStockService = MockStockService();
    mockTransactionService = MockTransactionService();
    controller = CylinderStockController(mockRepository, mockStockService, mockTransactionService);
  });

  group('CylinderStockController', () {
    group('getStocksByStatus', () {
      test('should return stocks by status from repository', () async {
        // Arrange
        final stocks = [
          CylinderStock(
            id: 'stock-1',
            cylinderId: 'cylinder-1',
            weight: 12,
            status: CylinderStatus.full,
            quantity: 100,
            enterpriseId: TestIds.enterprise1,
            updatedAt: DateTime(2026, 1, 1),
          ),
        ];
        when(mockRepository.getStocksByStatus(
          TestIds.enterprise1,
          CylinderStatus.full,
          siteId: anyNamed('siteId'),
        )).thenAnswer((_) async => stocks);

        // Act
        final result = await controller.getStocksByStatus(
          TestIds.enterprise1,
          CylinderStatus.full,
        );

        // Assert
        expect(result, equals(stocks));
        verify(mockRepository.getStocksByStatus(
          TestIds.enterprise1,
          CylinderStatus.full,
          siteId: anyNamed('siteId'),
        )).called(1);
      });
    });

    group('changeStockStatus', () {
      test('should change stock status via service', () async {
        // Arrange
        const stockId = 'stock-1';
        when(mockStockService.changeStockStatus(
          stockId,
          CylinderStatus.emptyAtStore,
        )).thenAnswer((_) async => {});

        // Act
        await controller.changeStockStatus(stockId, CylinderStatus.emptyAtStore);

        // Assert
        verify(mockStockService.changeStockStatus(
          stockId,
          CylinderStatus.emptyAtStore,
        )).called(1);
      });
    });

    group('adjustStockQuantity', () {
      test('should adjust stock quantity via transaction service', () async {
        // Arrange
        const stockId = 'stock-1';
        final stock = CylinderStock(
          id: stockId,
          cylinderId: 'cylinder-1',
          weight: 12,
          status: CylinderStatus.full,
          quantity: 100,
          enterpriseId: TestIds.enterprise1,
          updatedAt: DateTime.now(),
        );
        
        when(mockRepository.getStockById(stockId)).thenAnswer((_) async => stock);
        when(mockTransactionService.executeStockAdjustment(
          stock: anyNamed('stock'),
          newQuantity: anyNamed('newQuantity'),
          userId: anyNamed('userId'),
          reason: anyNamed('reason'),
        )).thenAnswer((_) async => {});

        // Act
        await controller.adjustStockQuantity(stockId, 50, userId: 'user-1', reason: 'Correction');

        // Assert
        verify(mockTransactionService.executeStockAdjustment(
          stock: anyNamed('stock'),
          newQuantity: 50,
          userId: 'user-1',
          reason: 'Correction',
        )).called(1);
      });
    });

    group('getAvailableStock', () {
      test('should return available stock from service', () async {
        // Arrange
        when(mockStockService.getAvailableStock(
          TestIds.enterprise1,
          12,
          siteId: anyNamed('siteId'),
        )).thenAnswer((_) async => 100);

        // Act
        final result = await controller.getAvailableStock(
          TestIds.enterprise1,
          12,
        );

        // Assert
        expect(result, equals(100));
        verify(mockStockService.getAvailableStock(
          TestIds.enterprise1,
          12,
          siteId: anyNamed('siteId'),
        )).called(1);
      });
    });
  });
}
