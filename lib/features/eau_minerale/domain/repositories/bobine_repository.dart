import '../entities/bobine.dart';

/// Repository pour gérer les bobines.
abstract class BobineRepository {
  /// Récupère toutes les bobines.
  Future<List<Bobine>> fetchBobines({
    bool? estDisponible,
  });

  /// Récupère une bobine par son ID.
  Future<Bobine?> fetchBobineById(String id);

  /// Récupère une bobine par sa référence.
  Future<Bobine?> fetchBobineByReference(String reference);

  /// Crée une nouvelle bobine.
  Future<Bobine> createBobine(Bobine bobine);

  /// Met à jour une bobine.
  Future<Bobine> updateBobine(Bobine bobine);

  /// Supprime une bobine.
  Future<void> deleteBobine(String id);
}

