
import '../entities/boutique_settings.dart';

abstract class BoutiqueSettingsRepository {
  Future<BoutiqueSettings?> getSettings(String enterpriseId);
  Stream<BoutiqueSettings?> watchSettings(String enterpriseId);
  Future<void> saveSettings(BoutiqueSettings settings);
}
