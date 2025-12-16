import '../../domain/entities/daily_worker.dart';
import '../../domain/repositories/daily_worker_repository.dart';
import '../services/daily_worker_storage_service.dart';

/// Repository mock pour les ouvriers journaliers.
/// Utilise DailyWorkerStorageService pour le stockage persistant.
class MockDailyWorkerRepository implements DailyWorkerRepository {
  final DailyWorkerStorageService _storage = DailyWorkerStorageService.instance;

  @override
  Future<List<DailyWorker>> fetchAllWorkers() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final workers = await _storage.getAllWorkers();
    return workers..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<DailyWorker?> fetchWorkerById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return await _storage.getWorkerById(id);
  }

  @override
  Future<DailyWorker> createWorker(DailyWorker worker) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return await _storage.addWorker(worker);
  }

  @override
  Future<DailyWorker> updateWorker(DailyWorker worker) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return await _storage.updateWorker(worker);
  }

  @override
  Future<void> deleteWorker(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    await _storage.deleteWorker(id);
  }
}
