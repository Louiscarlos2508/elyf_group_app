import '../../domain/entities/daily_worker.dart';

/// Service de stockage pour les ouvriers journaliers (mock).
/// TODO: Implémenter avec Isar quand le schéma sera défini.
class DailyWorkerStorageService {
  static final DailyWorkerStorageService instance = DailyWorkerStorageService._();
  DailyWorkerStorageService._();

  /// Récupère tous les ouvriers.
  Future<List<DailyWorker>> getAllWorkers() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.from(_mockWorkers);
  }

  /// Récupère un ouvrier par ID.
  Future<DailyWorker?> getWorkerById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _mockWorkers.firstWhere((w) => w.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Ajoute un nouvel ouvrier.
  Future<DailyWorker> addWorker(DailyWorker worker) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _mockWorkers.add(worker);
    return worker;
  }

  /// Met à jour un ouvrier existant.
  Future<DailyWorker> updateWorker(DailyWorker worker) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockWorkers.indexWhere((w) => w.id == worker.id);
    if (index != -1) {
      _mockWorkers[index] = worker;
    }
    return worker;
  }

  /// Supprime un ouvrier.
  Future<void> deleteWorker(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _mockWorkers.removeWhere((w) => w.id == id);
  }

  // Données mock temporaires
  static final List<DailyWorker> _mockWorkers = [
    DailyWorker(
      id: 'worker-1',
      name: 'Amadou Diallo',
      phone: '+221 77 123 45 67',
      salaireJournalier: 5000,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    DailyWorker(
      id: 'worker-2',
      name: 'Fatou Sall',
      phone: '+221 77 234 56 78',
      salaireJournalier: 5000,
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
    ),
    DailyWorker(
      id: 'worker-3',
      name: 'Ibrahima Ba',
      phone: '+221 77 345 67 89',
      salaireJournalier: 5500,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
  ];
}
