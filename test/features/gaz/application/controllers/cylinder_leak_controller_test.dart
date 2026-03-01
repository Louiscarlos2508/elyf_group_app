import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:elyf_groupe_app/features/gaz/application/controllers/cylinder_leak_controller.dart';
import 'package:elyf_groupe_app/features/gaz/domain/repositories/cylinder_leak_repository.dart';
import 'package:elyf_groupe_app/features/gaz/domain/repositories/cylinder_stock_repository.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/cylinder_leak.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/cylinder_stock.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/cylinder.dart';
import '../../../../helpers/test_helpers.dart';

import 'cylinder_leak_controller_test.mocks.dart';

import 'package:elyf_groupe_app/features/gaz/domain/services/transaction_service.dart';

@GenerateMocks([CylinderLeakRepository, CylinderStockRepository, TransactionService])
void main() {
  late CylinderLeakController controller;
  late MockCylinderLeakRepository mockLeakRepository;
  late MockCylinderStockRepository mockStockRepository;
  late MockTransactionService mockTransactionService;

  setUp(() {
    mockLeakRepository = MockCylinderLeakRepository();
    mockStockRepository = MockCylinderStockRepository();
    mockTransactionService = MockTransactionService();
    controller = CylinderLeakController(mockLeakRepository, mockStockRepository, mockTransactionService);
  });

  group('CylinderLeakController', () {
    group('getLeaks', () {
      test('should return leaks from repository', () async {
        // Arrange
        final leaks = <CylinderLeak>[];
        when(mockLeakRepository.getLeaks(
          TestIds.enterprise1,
          status: anyNamed('status'),
        )).thenAnswer((_) async => leaks);

        // Act
        final result = await controller.getLeaks(TestIds.enterprise1);

        // Assert
        expect(result, equals(leaks));
        verify(mockLeakRepository.getLeaks(
          TestIds.enterprise1,
          status: anyNamed('status'),
        )).called(1);
      });
    });

    group('reportLeak', () {
      test('should report leak via transaction service', () async {
        // Arrange
        const cylinderId = 'cyl-1';
        const weight = 6;

        when(mockTransactionService.executeLeakDeclaration(
          leak: anyNamed('leak'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async => {});

        // Act
        await controller.reportLeak(
          cylinderId,
          weight,
          TestIds.enterprise1,
          userId: 'user-1',
        );

        // Assert
        verify(mockTransactionService.executeLeakDeclaration(
          leak: anyNamed('leak'),
          userId: anyNamed('userId'),
        )).called(1);
      });
    });

    group('markAsSentForExchange', () {
      test('should mark leak as sent for exchange', () async {
        // Arrange
        const leakId = 'leak-1';
        when(mockLeakRepository.markAsSentForExchange(leakId))
            .thenAnswer((_) async => {});

        // Act
        await controller.markAsSentForExchange(leakId);

        // Assert
        verify(mockLeakRepository.markAsSentForExchange(leakId)).called(1);
      });
    });
  });
}
