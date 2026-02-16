
import '../entities/wholesaler.dart';

/// Interface pour la gestion des grossistes.
abstract class WholesalerRepository {
  /// Récupère tous les grossistes d'une entreprise.
  Future<List<Wholesaler>> getWholesalers(String enterpriseId);

  /// Récupère un grossiste par son identifiant.
  Future<Wholesaler?> getWholesalerById(String id);

  /// Crée un nouveau grossiste.
  Future<void> createWholesaler(Wholesaler wholesaler);

  /// Met à jour un grossiste existant.
  Future<void> updateWholesaler(Wholesaler wholesaler);

  /// Supprime un grossiste.
  Future<void> deleteWholesaler(String id);

  /// Recherche des grossistes par nom ou téléphone.
  Future<List<Wholesaler>> searchWholesalers(String enterpriseId, String query);
}
