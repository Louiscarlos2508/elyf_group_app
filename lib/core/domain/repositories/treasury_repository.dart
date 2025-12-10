import '../entities/treasury.dart';

/// Repository pour gérer la trésorerie.
abstract class TreasuryRepository {
  /// Récupère la trésorerie d'un module.
  Future<Treasury> fetchTreasury(String moduleId);

  /// Met à jour la trésorerie.
  Future<Treasury> updateTreasury(Treasury treasury);

  /// Crée une nouvelle trésorerie pour un module.
  Future<Treasury> createTreasury(Treasury treasury);
}

