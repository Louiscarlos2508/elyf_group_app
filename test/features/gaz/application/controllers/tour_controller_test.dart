import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:elyf_groupe_app/features/gaz/application/controllers/tour_controller.dart';
import 'package:elyf_groupe_app/features/gaz/domain/repositories/tour_repository.dart';
import 'package:elyf_groupe_app/features/gaz/domain/services/tour_service.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/tour.dart';
import '../../../../helpers/test_helpers.dart';

import 'tour_controller_test.mocks.dart';

@GenerateMocks([TourRepository, TourService])
void main() {
  late TourController controller;
  late MockTourRepository mockRepository;
  late MockTourService mockService;

  setUp(() {
    mockRepository = MockTourRepository();
    mockService = MockTourService();
    controller = TourController(repository: mockRepository, service: mockService);
  });

  group('TourController', () {
    group('getTours', () {
      test('should return tours from repository', () async {
        // Arrange
        final tours = <Tour>[];
        when(mockRepository.getTours(
          TestIds.enterprise1,
          status: anyNamed('status'),
          from: anyNamed('from'),
          to: anyNamed('to'),
        )).thenAnswer((_) async => tours);

        // Act
        final result = await controller.getTours(TestIds.enterprise1);

        // Assert
        expect(result, equals(tours));
        verify(mockRepository.getTours(
          TestIds.enterprise1,
          status: anyNamed('status'),
          from: anyNamed('from'),
          to: anyNamed('to'),
        )).called(1);
      });
    });

    group('createTour', () {
      test('should create tour via repository', () async {
        // Arrange
        final tour = Tour(
          id: '',
          enterpriseId: TestIds.enterprise1,
          tourDate: DateTime(2026, 1, 1),
          status: TourStatus.collection,
          collections: const [],
          loadingFeePerBottle: 100.0,
          unloadingFeePerBottle: 100.0,
        );
        when(mockRepository.createTour(any)).thenAnswer((_) async => 'tour-1');

        // Act
        final result = await controller.createTour(tour);

        // Assert
        expect(result, equals('tour-1'));
        verify(mockRepository.createTour(tour)).called(1);
      });
    });

    group('moveToNextStep', () {
      test('should move to next step via service', () async {
        // Arrange
        const tourId = 'tour-1';
        when(mockService.moveToNextStep(tourId)).thenAnswer((_) async => {});

        // Act
        await controller.moveToNextStep(tourId);

        // Assert
        verify(mockService.moveToNextStep(tourId)).called(1);
      });
    });
  });
}
