
import '../entities/immobilier_settings.dart';

abstract class ImmobilierSettingsRepository {
  Future<ImmobilierSettings?> getSettings(String enterpriseId);
  Stream<ImmobilierSettings?> watchSettings(String enterpriseId);
  Future<void> saveSettings(ImmobilierSettings settings);
}
