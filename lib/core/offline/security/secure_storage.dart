import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../errors/error_handler.dart';
import '../../logging/app_logger.dart';

/// Provides secure handling of sensitive data.
///
/// Note: For truly sensitive data (passwords, tokens), use flutter_secure_storage.
/// This class provides basic obfuscation for offline data that doesn't require
/// encryption but shouldn't be stored in plain text.
class SecureDataHandler {
  SecureDataHandler._();

  /// Fields that should be treated as sensitive.
  static const Set<String> sensitiveFields = {
    'password',
    'token',
    'secret',
    'apiKey',
    'api_key',
    'accessToken',
    'access_token',
    'refreshToken',
    'refresh_token',
    'pin',
    'otp',
    'creditCard',
    'credit_card',
    'cvv',
    'ssn',
  };

  /// Checks if a field name indicates sensitive data.
  static bool isSensitiveField(String fieldName) {
    final lower = fieldName.toLowerCase();
    return sensitiveFields.any((s) => lower.contains(s.toLowerCase()));
  }

  /// Removes sensitive fields from a map before storage.
  ///
  /// Returns a new map with sensitive fields removed or masked.
  static Map<String, dynamic> removeSensitiveData(Map<String, dynamic> data) {
    final result = <String, dynamic>{};

    for (final entry in data.entries) {
      if (isSensitiveField(entry.key)) {
        // Log in debug mode to help identify what's being filtered
        if (kDebugMode) {
          AppLogger.debug(
            'Removing sensitive field: ${entry.key}',
            name: 'offline.security',
          );
        }
        continue;
      }

      if (entry.value is Map<String, dynamic>) {
        result[entry.key] = removeSensitiveData(
          entry.value as Map<String, dynamic>,
        );
      } else if (entry.value is List) {
        result[entry.key] = _processList(entry.value as List);
      } else {
        result[entry.key] = entry.value;
      }
    }

    return result;
  }

  static List<dynamic> _processList(List<dynamic> list) {
    return list.map((item) {
      if (item is Map<String, dynamic>) {
        return removeSensitiveData(item);
      }
      return item;
    }).toList();
  }

  /// Basic obfuscation for non-critical but private data.
  ///
  /// This is NOT encryption - just basic obfuscation to prevent
  /// casual viewing. For real security, use proper encryption.
  static String obfuscate(String data) {
    final bytes = utf8.encode(data);
    final obfuscated = Uint8List(bytes.length);

    for (var i = 0; i < bytes.length; i++) {
      obfuscated[i] = bytes[i] ^ 0x5A; // Simple XOR
    }

    return base64Encode(obfuscated);
  }

  /// Reverses basic obfuscation.
  static String deobfuscate(String obfuscated) {
    try {
      final bytes = base64Decode(obfuscated);
      final deobfuscated = Uint8List(bytes.length);

      for (var i = 0; i < bytes.length; i++) {
        deobfuscated[i] = bytes[i] ^ 0x5A;
      }

      return utf8.decode(deobfuscated);
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.warning(
        'Failed to deobfuscate data: ${appException.message}',
        name: 'offline.security',
        error: e,
        stackTrace: stackTrace,
      );
      return '';
    }
  }
}

/// Mixin for entities that contain potentially sensitive data.
mixin SensitiveDataMixin {
  /// Returns a sanitized version of the entity data for logging.
  Map<String, dynamic> toSafeLogMap(Map<String, dynamic> data) {
    return SecureDataHandler.removeSensitiveData(data);
  }
}
