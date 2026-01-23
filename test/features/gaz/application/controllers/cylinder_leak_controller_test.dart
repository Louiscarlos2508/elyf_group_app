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

@GenerateMocks([CylinderLeakRepository, CylinderStockRepository])
void main() {
  late CylinderLeakController controller;
  late MockCylinderLeakRepository mockLeakRepository;
  late MockCylinderStockRepository mockStockRepository;

  setUp(() {
    mockLeakRepository = MockCylinderLeakRepository();
    mockStockRepository = MockCylinderStockRepository();
    controller = CylinderLeakController(mockLeakRepository, mockStockRepository);
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
      test('should report leak and update stock', () async {
        // Arrange
        const cylinderId = 'cylinder-1';
        const weight = 12;
        final stocks = [
          CylinderStock(
            id: 'stock-1',
            cylinderId: cylinderId,
            weight: weight,
            status: CylinderStatus.full,
            quantity: 10,
            enterpriseId: TestIds.enterprise1,
            updatedAt: DateTime(2026, 1, 1),
          ),
        ];
        when(mockLeakRepository.reportLeak(any))
            .thenAnswer((_) async => 'leak-1');
        when(mockStockRepository.getStocksByWeight(
          TestIds.enterprise1,
          weight,
        )).thenAnswer((_) async => stocks);
        when(mockStockRepository.updateStockQuantity(any, any))
            .thenAnswer((_) async => {});

        // Act
        final result = await controller.reportLeak(
          cylinderId,
          weight,
          TestIds.enterprise1,
        );

        // Assert
        expect(result, equals('leak-1'));
        verify(mockLeakRepository.reportLeak(any)).called(1);
        verify(mockStockRepository.getStocksByWeight(
          TestIds.enterprise1,
          weight,
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
