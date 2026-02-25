import '../entities/collection.dart';

/// Repository pour la gestion des collectes de bouteilles.
abstract class CollectionRepository {
  /// Enregistre une nouvelle collecte.
  Future<void> saveCollection(Collection collection, String enterpriseId);

  /// Récupère les collectes d'une entreprise pour une période donnée.
  Future<List<Collection>> getCollections(
    String enterpriseId, {
    DateTime? startDate,
    DateTime? endDate,
    List<String>? enterpriseIds, // Optionnel: pour vue consolidée
  });

  /// Surveille les collectes en temps réel.
  Stream<List<Collection>> watchCollections(
    String enterpriseId, {
    List<String>? enterpriseIds,
  });

  /// Récupère une collecte par son ID.
  Future<Collection?> getCollectionById(String id);
}
