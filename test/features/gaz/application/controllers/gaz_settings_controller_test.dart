import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:elyf_groupe_app/features/gaz/application/controllers/gaz_settings_controller.dart';
import 'package:elyf_groupe_app/features/gaz/domain/repositories/gaz_settings_repository.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/gaz_settings.dart';
import '../../../../helpers/test_helpers.dart';

import 'gaz_settings_controller_test.mocks.dart';

@GenerateMocks([GazSettingsRepository])
void main() {
  late GazSettingsController controller;
  late MockGazSettingsRepository mockRepository;

  setUp(() {
    mockRepository = MockGazSettingsRepository();
    controller = GazSettingsController(repository: mockRepository);
  });

  group('GazSettingsController', () {
    group('getSettings', () {
      test('should return settings from repository', () async {
        // Arrange
        final settings = GazSettings(
          enterpriseId: TestIds.enterprise1,
          moduleId: TestIds.moduleGaz,
        );
        when(mockRepository.getSettings(
          enterpriseId: TestIds.enterprise1,
          moduleId: TestIds.moduleGaz,
        )).thenAnswer((_) async => settings);

        // Act
        final result = await controller.getSettings(
          enterpriseId: TestIds.enterprise1,
          moduleId: TestIds.moduleGaz,
        );

        // Assert
        expect(result, equals(settings));
        verify(mockRepository.getSettings(
          enterpriseId: TestIds.enterprise1,
          moduleId: TestIds.moduleGaz,
        )).called(1);
      });
    });

    group('saveSettings', () {
      test('should save settings via repository', () async {
        // Arrange
        final settings = GazSettings(
          enterpriseId: TestIds.enterprise1,
          moduleId: TestIds.moduleGaz,
        );
        when(mockRepository.saveSettings(any)).thenAnswer((_) async => {});

        // Act
        await controller.saveSettings(settings);

        // Assert
        verify(mockRepository.saveSettings(settings)).called(1);
      });
    });

    group('setWholesalePrice', () {
      test('should set wholesale price when settings exist', () async {
        // Arrange
        final existing = GazSettings(
          enterpriseId: TestIds.enterprise1,
          moduleId: TestIds.moduleGaz,
        );
        when(mockRepository.getSettings(
          enterpriseId: TestIds.enterprise1,
          moduleId: TestIds.moduleGaz,
        )).thenAnswer((_) async => existing);
        when(mockRepository.saveSettings(any)).thenAnswer((_) async => {});

        // Act
        await controller.setWholesalePrice(
          enterpriseId: TestIds.enterprise1,
          moduleId: TestIds.moduleGaz,
          weight: 12,
          price: 5500.0,
        );

        // Assert
        verify(mockRepository.getSettings(
          enterpriseId: TestIds.enterprise1,
          moduleId: TestIds.moduleGaz,
        )).called(1);
        verify(mockRepository.saveSettings(any)).called(1);
      });

      test('should create new settings when none exist', () async {
        // Arrange
        when(mockRepository.getSettings(
          enterpriseId: TestIds.enterprise1,
          moduleId: TestIds.moduleGaz,
        )).thenAnswer((_) async => null);
        when(mockRepository.saveSettings(any)).thenAnswer((_) async => {});

        // Act
        await controller.setWholesalePrice(
          enterpriseId: TestIds.enterprise1,
          moduleId: TestIds.moduleGaz,
          weight: 12,
          price: 5500.0,
        );

        // Assert
        verify(mockRepository.saveSettings(any)).called(1);
      });
    });

    group('getWholesalePrice', () {
      test('should return wholesale price from settings', () async {
        // Arrange
        final settings = GazSettings(
          enterpriseId: TestIds.enterprise1,
          moduleId: TestIds.moduleGaz,
        ).setWholesalePrice(12, 5500.0);
        when(mockRepository.getSettings(
          enterpriseId: TestIds.enterprise1,
          moduleId: TestIds.moduleGaz,
        )).thenAnswer((_) async => settings);

        // Act
        final result = await controller.getWholesalePrice(
          enterpriseId: TestIds.enterprise1,
          moduleId: TestIds.moduleGaz,
          weight: 12,
        );

        // Assert
        expect(result, equals(5500.0));
      });
    });
  });
}
