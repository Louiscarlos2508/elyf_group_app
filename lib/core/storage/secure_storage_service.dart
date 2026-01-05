import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service wrapper pour flutter_secure_storage.
/// 
/// Fournit une interface simplifiée pour stocker et récupérer des données
/// sensibles de manière sécurisée. Utilise le Keychain sur iOS et
/// EncryptedSharedPreferences sur Android.
class SecureStorageService {
  static const SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  const SecureStorageService._internal();

  // Configuration pour Android (requis pour Android 6.0+)
  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  // Configuration pour iOS/macOS
  static const IOSOptions _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: _androidOptions,
    iOptions: _iosOptions,
  );

  /// Sauvegarde une valeur de manière sécurisée.
  /// 
  /// [key] : Clé unique pour identifier la valeur
  /// [value] : Valeur à sauvegarder (sera stockée de manière chiffrée)
  Future<void> write(String key, String? value) async {
    if (value == null) {
      await _storage.delete(key: key);
    } else {
      await _storage.write(key: key, value: value);
    }
  }

  /// Récupère une valeur de manière sécurisée.
  /// 
  /// [key] : Clé unique de la valeur à récupérer
  /// Retourne la valeur ou `null` si la clé n'existe pas
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  /// Supprime une valeur.
  /// 
  /// [key] : Clé unique de la valeur à supprimer
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  /// Supprime toutes les valeurs stockées.
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  /// Vérifie si une clé existe.
  /// 
  /// [key] : Clé à vérifier
  /// Retourne `true` si la clé existe, `false` sinon
  Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }

  /// Récupère toutes les clés stockées.
  /// 
  /// Retourne une map de toutes les clés/valeurs stockées
  Future<Map<String, String>> readAll() async {
    return await _storage.readAll();
  }
}

