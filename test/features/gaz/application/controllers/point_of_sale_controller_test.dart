import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:elyf_groupe_app/features/gaz/application/controllers/point_of_sale_controller.dart';
import 'package:elyf_groupe_app/features/gaz/domain/repositories/point_of_sale_repository.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/point_of_sale.dart';
import '../../../../helpers/test_helpers.dart';

import 'point_of_sale_controller_test.mocks.dart';

@GenerateMocks([PointOfSaleRepository])
void main() {
  late PointOfSaleController controller;
  late MockPointOfSaleRepository mockRepository;

  setUp(() {
    mockRepository = MockPointOfSaleRepository();
    controller = PointOfSaleController(mockRepository);
  });

  group('PointOfSaleController', () {
    group('getPointsOfSale', () {
      test('should return list of points of sale', () async {
        // Arrange
        final pointsOfSale = [
          const PointOfSale(
            id: 'pos-1',
            name: 'POS 1',
            address: 'Address 1',
            contact: '+237 6 12 34 56 78',
            parentEnterpriseId: TestIds.enterprise1,
            moduleId: TestIds.moduleGaz,
          ),
        ];
        when(mockRepository.getPointsOfSale(
          enterpriseId: TestIds.enterprise1,
          moduleId: TestIds.moduleGaz,
        )).thenAnswer((_) async => pointsOfSale);

        // Act
        final result = await controller.getPointsOfSale(
          enterpriseId: TestIds.enterprise1,
          moduleId: TestIds.moduleGaz,
        );

        // Assert
        expect(result, equals(pointsOfSale));
        verify(mockRepository.getPointsOfSale(
          enterpriseId: TestIds.enterprise1,
          moduleId: TestIds.moduleGaz,
        )).called(1);
      });
    });

    group('getPointOfSaleById', () {
      test('should return point of sale when found', () async {
        // Arrange
        const pointOfSale = PointOfSale(
          id: 'pos-1',
          name: 'POS 1',
          address: 'Address 1',
          contact: '+237 6 12 34 56 78',
          parentEnterpriseId: TestIds.enterprise1,
          moduleId: TestIds.moduleGaz,
        );
        when(mockRepository.getPointOfSaleById('pos-1'))
            .thenAnswer((_) async => pointOfSale);

        // Act
        final result = await controller.getPointOfSaleById('pos-1');

        // Assert
        expect(result, equals(pointOfSale));
        verify(mockRepository.getPointOfSaleById('pos-1')).called(1);
      });
    });

    group('addPointOfSale', () {
      test('should add point of sale via repository', () async {
        // Arrange
        const pointOfSale = PointOfSale(
          id: 'pos-1',
          name: 'POS 1',
          address: 'Address 1',
          contact: '+237 6 12 34 56 78',
          parentEnterpriseId: TestIds.enterprise1,
          moduleId: TestIds.moduleGaz,
        );
        when(mockRepository.addPointOfSale(any)).thenAnswer((_) async => {});

        // Act
        await controller.addPointOfSale(pointOfSale);

        // Assert
        verify(mockRepository.addPointOfSale(pointOfSale)).called(1);
      });
    });

    group('updatePointOfSale', () {
      test('should update point of sale via repository', () async {
        // Arrange
        const pointOfSale = PointOfSale(
          id: 'pos-1',
          name: 'POS 1 Updated',
          address: 'Address 1',
          contact: '+237 6 12 34 56 78',
          parentEnterpriseId: TestIds.enterprise1,
          moduleId: TestIds.moduleGaz,
        );
        when(mockRepository.updatePointOfSale(any))
            .thenAnswer((_) async => {});

        // Act
        await controller.updatePointOfSale(pointOfSale);

        // Assert
        verify(mockRepository.updatePointOfSale(pointOfSale)).called(1);
      });
    });

    group('deletePointOfSale', () {
      test('should delete point of sale via repository', () async {
        // Arrange
        const posId = 'pos-1';
        when(mockRepository.deletePointOfSale(posId))
            .thenAnswer((_) async => {});

        // Act
        await controller.deletePointOfSale(posId);

        // Assert
        verify(mockRepository.deletePointOfSale(posId)).called(1);
      });
    });
  });
}
