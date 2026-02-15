import '../entities/exchange_record.dart';

/// Interface pour la gestion de la persistance des échanges de bouteilles.
abstract class ExchangeRepository {
  /// Récupère tous les échanges pour une entreprise.
  Future<List<ExchangeRecord>> getExchanges(String enterpriseId);

  /// Observe les échanges en temps réel.
  Stream<List<ExchangeRecord>> watchExchanges(String enterpriseId);

  /// Récupère un échange par son ID.
  Future<ExchangeRecord?> getExchangeById(String id);

  /// Ajoute un nouvel échange.
  Future<void> addExchange(ExchangeRecord exchange);

  /// Supprime un échange.
  Future<void> deleteExchange(String id);
}
