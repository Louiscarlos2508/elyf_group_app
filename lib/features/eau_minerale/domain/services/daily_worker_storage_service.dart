import 'package:elyf_groupe_app/shared.dart';
import '../../domain/entities/daily_worker.dart';

/// Service de stockage pour les ouvriers journaliers.
///
/// Utilise un stockage en mémoire pour le moment.
/// Note: Drift est utilisé exclusivement pour le stockage offline (pas ObjectBox).
class DailyWorkerStorageService {
  DailyWorkerStorageService._();

  static final DailyWorkerStorageService instance =
      DailyWorkerStorageService._();

  final Map<String, DailyWorker> _workers = {};

  /// Récupère tous les ouvriers.
  Future<List<DailyWorker>> getAllWorkers() async {
    return _workers.values.toList();
  }

  /// Récupère un ouvrier par son ID.
  Future<DailyWorker?> getWorkerById(String id) async {
    return _workers[id];
  }

  /// Ajoute un nouvel ouvrier.
  Future<DailyWorker> addWorker(DailyWorker worker) async {
    final newWorker = DailyWorker(
      id: worker.id.isEmpty ? IdGenerator.generate() : worker.id,
      name: worker.name,
      phone: worker.phone,
      salaireJournalier: worker.salaireJournalier,
      joursTravailles: worker.joursTravailles,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _workers[newWorker.id] = newWorker;
    return newWorker;
  }

  /// Met à jour un ouvrier existant.
  Future<DailyWorker> updateWorker(DailyWorker worker) async {
    final updatedWorker = DailyWorker(
      id: worker.id,
      name: worker.name,
      phone: worker.phone,
      salaireJournalier: worker.salaireJournalier,
      joursTravailles: worker.joursTravailles,
      createdAt: worker.createdAt,
      updatedAt: DateTime.now(),
    );
    _workers[worker.id] = updatedWorker;
    return updatedWorker;
  }

  /// Supprime un ouvrier.
  Future<void> deleteWorker(String id) async {
    _workers.remove(id);
  }

  /// Efface tous les ouvriers (pour les tests).
  Future<void> clear() async {
    _workers.clear();
  }
}
