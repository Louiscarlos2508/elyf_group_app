import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:elyf_groupe_app/features/gaz/application/controllers/gas_controller.dart';
import 'package:elyf_groupe_app/features/gaz/domain/repositories/gas_repository.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/cylinder.dart';
import '../../../../helpers/test_helpers.dart';

import 'gas_controller_test.mocks.dart';

@GenerateMocks([GasRepository])
void main() {
  late GasController controller;
  late MockGasRepository mockRepository;

  setUp(() {
    mockRepository = MockGasRepository();
    controller = GasController(mockRepository);
  });

  group('GasController', () {
    group('loadCylinders', () {
      test('should load cylinders and update state', () async {
        // Arrange
        final cylinders = [
          createTestCylinder(id: 'cylinder-1'),
          createTestCylinder(id: 'cylinder-2'),
        ];
        when(mockRepository.getCylinders()).thenAnswer((_) async => cylinders);

        // Act
        await controller.loadCylinders();

        // Assert
        expect(controller.cylinders, equals(cylinders));
        expect(controller.isLoading, isFalse);
        verify(mockRepository.getCylinders()).called(1);
      });

      test('should set isLoading to true during loading', () async {
        // Arrange
        when(mockRepository.getCylinders()).thenAnswer(
          (_) async => Future.delayed(
            const Duration(milliseconds: 100),
            () => <Cylinder>[],
          ),
        );

        // Act
        final loadFuture = controller.loadCylinders();

        // Assert
        expect(controller.isLoading, isTrue);
        await loadFuture;
        expect(controller.isLoading, isFalse);
      });
    });

    group('loadSales', () {
      test('should load sales and update state', () async {
        // Arrange
        final sales = [
          createTestGasSale(id: 'sale-1'),
          createTestGasSale(id: 'sale-2'),
        ];
        when(mockRepository.getSales(from: anyNamed('from'), to: anyNamed('to')))
            .thenAnswer((_) async => sales);

        // Act
        await controller.loadSales();

        // Assert
        expect(controller.sales, equals(sales));
        expect(controller.isLoading, isFalse);
        verify(mockRepository.getSales(from: anyNamed('from'), to: anyNamed('to')))
            .called(1);
      });

      test('should load sales with date range', () async {
        // Arrange
        final from = DateTime(2026, 1, 1);
        final to = DateTime(2026, 1, 31);
        final sales = [createTestGasSale(id: 'sale-1')];
        when(mockRepository.getSales(from: anyNamed('from'), to: anyNamed('to')))
            .thenAnswer((_) async => sales);

        // Act
        await controller.loadSales(from: from, to: to);

        // Assert
        expect(controller.sales, equals(sales));
        verify(mockRepository.getSales(from: from, to: to)).called(1);
      });
    });

    group('addSale', () {
      test('should add sale and reload sales', () async {
        // Arrange
        final sale = createTestGasSale(id: 'sale-1');
        when(mockRepository.addSale(any)).thenAnswer((_) async => {});
        when(mockRepository.getSales(from: anyNamed('from'), to: anyNamed('to')))
            .thenAnswer((_) async => [sale]);

        // Act
        await controller.addSale(sale);

        // Assert
        verify(mockRepository.addSale(sale)).called(1);
        verify(mockRepository.getSales(from: anyNamed('from'), to: anyNamed('to')))
            .called(1);
      });
    });

    group('updateSale', () {
      test('should update sale and reload sales', () async {
        // Arrange
        final sale = createTestGasSale(id: 'sale-1', quantity: 2);
        when(mockRepository.updateSale(any)).thenAnswer((_) async => {});
        when(mockRepository.getSales(from: anyNamed('from'), to: anyNamed('to')))
            .thenAnswer((_) async => [sale]);

        // Act
        await controller.updateSale(sale);

        // Assert
        verify(mockRepository.updateSale(sale)).called(1);
        verify(mockRepository.getSales(from: anyNamed('from'), to: anyNamed('to')))
            .called(1);
      });
    });

    group('deleteSale', () {
      test('should delete sale and reload sales', () async {
        // Arrange
        const saleId = 'sale-1';
        when(mockRepository.deleteSale(saleId)).thenAnswer((_) async => {});
        when(mockRepository.getSales(from: anyNamed('from'), to: anyNamed('to')))
            .thenAnswer((_) async => []);

        // Act
        await controller.deleteSale(saleId);

        // Assert
        verify(mockRepository.deleteSale(saleId)).called(1);
        verify(mockRepository.getSales(from: anyNamed('from'), to: anyNamed('to')))
            .called(1);
      });
    });

    group('updateCylinderStock', () {
      test('should update cylinder stock when cylinder exists', () async {
        // Arrange
        final cylinder = createTestCylinder(id: 'cylinder-1', stock: 100);
        when(mockRepository.getCylinders()).thenAnswer((_) async => [cylinder]);
        await controller.loadCylinders();
        when(mockRepository.updateCylinder(any)).thenAnswer((_) async => {});

        // Act
        await controller.updateCylinderStock('cylinder-1', 50);

        // Assert
        expect(controller.cylinders.first.stock, equals(50));
        verify(mockRepository.updateCylinder(any)).called(1);
      });

      test('should not update stock when cylinder does not exist', () async {
        // Arrange
        when(mockRepository.getCylinders()).thenAnswer((_) async => []);
        await controller.loadCylinders();

        // Act
        await controller.updateCylinderStock('cylinder-1', 50);

        // Assert
        verifyNever(mockRepository.updateCylinder(any));
      });
    });
  });
}
