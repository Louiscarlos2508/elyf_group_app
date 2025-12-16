import '../entities/daily_worker.dart';

/// Repository pour gérer les ouvriers journaliers.
abstract class DailyWorkerRepository {
  /// Récupère tous les ouvriers journaliers.
  Future<List<DailyWorker>> fetchAllWorkers();

  /// Récupère un ouvrier par son ID.
  Future<DailyWorker?> fetchWorkerById(String id);

  /// Crée un nouvel ouvrier journalier.
  Future<DailyWorker> createWorker(DailyWorker worker);

  /// Met à jour un ouvrier journalier existant.
  Future<DailyWorker> updateWorker(DailyWorker worker);

  /// Supprime un ouvrier journalier.
  Future<void> deleteWorker(String id);
}
