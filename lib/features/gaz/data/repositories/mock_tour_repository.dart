import 'dart:math';
import '../../domain/entities/tour.dart';
import '../../domain/repositories/tour_repository.dart';

/// Implémentation mock du repository des tours.
class MockTourRepository implements TourRepository {
  final List<Tour> _tours = [];
  final Random _random = Random();

  @override
  Future<List<Tour>> getTours(
    String enterpriseId, {
    TourStatus? status,
    DateTime? from,
    DateTime? to,
  }) async {
    return _tours.where((t) {
      if (t.enterpriseId != enterpriseId) return false;
      if (status != null && t.status != status) return false;
      if (from != null && t.tourDate.isBefore(from)) return false;
      if (to != null && t.tourDate.isAfter(to)) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.tourDate.compareTo(a.tourDate));
  }

  @override
  Future<Tour?> getTourById(String id) async {
    return _tours.where((t) => t.id == id).firstOrNull;
  }

  @override
  Future<String> createTour(Tour tour) async {
    final id = tour.id.isEmpty
        ? 'tour_${_random.nextInt(1000000)}'
        : tour.id;
    final newTour = tour.copyWith(id: id);
    _tours.add(newTour);
    return id;
  }

  @override
  Future<void> updateTour(Tour tour) async {
    final index = _tours.indexWhere((t) => t.id == tour.id);
    if (index != -1) {
      _tours[index] = tour;
    }
  }

  @override
  Future<void> updateStatus(String id, TourStatus status) async {
    final index = _tours.indexWhere((t) => t.id == id);
    if (index != -1) {
      final tour = _tours[index];
      final now = DateTime.now();

      Tour updated = tour.copyWith(status: status);

      switch (status) {
        case TourStatus.collection:
          // Déjà en collecte
          break;
        case TourStatus.transport:
          updated = updated.copyWith(collectionCompletedDate: now);
          break;
        case TourStatus.return_:
          updated = updated.copyWith(transportCompletedDate: now);
          break;
        case TourStatus.closure:
          updated = updated.copyWith(returnCompletedDate: now, closureDate: now);
          break;
        case TourStatus.cancelled:
          updated = updated.copyWith(cancelledDate: now);
          break;
      }

      _tours[index] = updated;
    }
  }

  @override
  Future<void> cancelTour(String id) async {
    await updateStatus(id, TourStatus.cancelled);
  }

  @override
  Future<void> deleteTour(String id) async {
    _tours.removeWhere((t) => t.id == id);
  }
}

