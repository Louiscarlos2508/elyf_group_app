import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:elyf_groupe_app/features/gaz/application/controllers/cylinder_controller.dart';
import 'package:elyf_groupe_app/features/gaz/domain/repositories/gas_repository.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/cylinder.dart';
import '../../../../helpers/test_helpers.dart';

import 'cylinder_controller_test.mocks.dart';

@GenerateMocks([GasRepository])
void main() {
  late CylinderController controller;
  late MockGasRepository mockRepository;

  setUp(() {
    mockRepository = MockGasRepository();
    controller = CylinderController(mockRepository);
  });

  group('CylinderController', () {
    group('getCylinders', () {
      test('should return list of cylinders from repository', () async {
        // Arrange
        final cylinders = [
          createTestCylinder(id: 'cylinder-1'),
          createTestCylinder(id: 'cylinder-2'),
        ];
        when(mockRepository.getCylinders()).thenAnswer((_) async => cylinders);

        // Act
        final result = await controller.getCylinders();

        // Assert
        expect(result, equals(cylinders));
        verify(mockRepository.getCylinders()).called(1);
      });
    });

    group('getCylinderById', () {
      test('should return cylinder when found', () async {
        // Arrange
        final cylinder = createTestCylinder(id: 'cylinder-1');
        when(mockRepository.getCylinderById('cylinder-1'))
            .thenAnswer((_) async => cylinder);

        // Act
        final result = await controller.getCylinderById('cylinder-1');

        // Assert
        expect(result, equals(cylinder));
        verify(mockRepository.getCylinderById('cylinder-1')).called(1);
      });

      test('should return null when cylinder not found', () async {
        // Arrange
        when(mockRepository.getCylinderById('cylinder-1'))
            .thenAnswer((_) async => null);

        // Act
        final result = await controller.getCylinderById('cylinder-1');

        // Assert
        expect(result, isNull);
        verify(mockRepository.getCylinderById('cylinder-1')).called(1);
      });
    });

    group('addCylinder', () {
      test('should add cylinder via repository', () async {
        // Arrange
        final cylinder = createTestCylinder(id: 'cylinder-1');
        when(mockRepository.addCylinder(any)).thenAnswer((_) async => {});

        // Act
        await controller.addCylinder(cylinder);

        // Assert
        verify(mockRepository.addCylinder(cylinder)).called(1);
      });
    });

    group('updateCylinder', () {
      test('should update cylinder via repository', () async {
        // Arrange
        final cylinder = createTestCylinder(id: 'cylinder-1', stock: 50);
        when(mockRepository.updateCylinder(any)).thenAnswer((_) async => {});

        // Act
        await controller.updateCylinder(cylinder);

        // Assert
        verify(mockRepository.updateCylinder(cylinder)).called(1);
      });
    });

    group('deleteCylinder', () {
      test('should delete cylinder via repository', () async {
        // Arrange
        const cylinderId = 'cylinder-1';
        when(mockRepository.deleteCylinder(cylinderId))
            .thenAnswer((_) async => {});

        // Act
        await controller.deleteCylinder(cylinderId);

        // Assert
        verify(mockRepository.deleteCylinder(cylinderId)).called(1);
      });
    });
  });
}
