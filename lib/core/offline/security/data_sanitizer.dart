import 'dart:convert';

/// Utility class for sanitizing and validating data before storage.
///
/// Provides protection against:
/// - Injection attacks in string fields
/// - Oversized data that could cause performance issues
/// - Invalid data types
class DataSanitizer {
  DataSanitizer._();

  /// Maximum allowed string length for single fields.
  static const int maxStringLength = 10000;

  /// Maximum allowed JSON data size in bytes.
  static const int maxJsonSizeBytes = 1024 * 1024; // 1MB

  /// Characters that should be escaped in strings.
  static final RegExp _dangerousChars = RegExp(r'[<>"\x00-\x1f]');

  /// Sanitizes a string value.
  ///
  /// - Trims whitespace
  /// - Limits length
  /// - Escapes potentially dangerous characters
  static String sanitizeString(String? value, {int? maxLength}) {
    if (value == null || value.isEmpty) return '';

    final effectiveMaxLength = maxLength ?? maxStringLength;
    var sanitized = value.trim();

    // Limit length
    if (sanitized.length > effectiveMaxLength) {
      sanitized = sanitized.substring(0, effectiveMaxLength);
    }

    // Escape dangerous characters
    sanitized = sanitized.replaceAllMapped(_dangerousChars, (match) {
      final char = match.group(0)!;
      return '\\u${char.codeUnitAt(0).toRadixString(16).padLeft(4, '0')}';
    });

    return sanitized;
  }

  /// Sanitizes a map for storage.
  ///
  /// Recursively sanitizes all string values and validates structure.
  static Map<String, dynamic> sanitizeMap(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};

    for (final entry in data.entries) {
      final key = sanitizeString(entry.key, maxLength: 100);
      if (key.isEmpty) continue;

      sanitized[key] = _sanitizeValue(entry.value);
    }

    return sanitized;
  }

  static dynamic _sanitizeValue(dynamic value) {
    if (value == null) return null;

    if (value is String) {
      return sanitizeString(value);
    }

    if (value is Map<String, dynamic>) {
      return sanitizeMap(value);
    }

    if (value is List) {
      return value.map(_sanitizeValue).toList();
    }

    if (value is num || value is bool) {
      return value;
    }

    // Convert unknown types to string
    return sanitizeString(value.toString());
  }

  /// Validates and limits JSON data size.
  ///
  /// Throws [DataSizeException] if data exceeds limit.
  static String validateJsonSize(String json) {
    final bytes = utf8.encode(json);
    if (bytes.length > maxJsonSizeBytes) {
      throw DataSizeException(
        'Data size ${bytes.length} exceeds maximum $maxJsonSizeBytes bytes',
      );
    }
    return json;
  }

  /// Sanitizes data and converts to JSON string.
  static String toSafeJson(Map<String, dynamic> data) {
    final sanitized = sanitizeMap(data);
    final json = jsonEncode(sanitized);
    return validateJsonSize(json);
  }

  /// Validates that an ID is safe.
  static bool isValidId(String? id) {
    if (id == null || id.isEmpty) return false;
    if (id.length > 100) return false;

    // Only allow alphanumeric, underscore, and hyphen
    return RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id);
  }

  /// Sanitizes an ID value.
  static String? sanitizeId(String? id) {
    if (id == null || id.isEmpty) return null;

    // Remove any characters that aren't alphanumeric, underscore, or hyphen
    final sanitized = id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');

    if (sanitized.isEmpty || sanitized.length > 100) return null;

    return sanitized;
  }
}

/// Exception thrown when data exceeds size limits.
class DataSizeException implements Exception {
  const DataSizeException(this.message);
  final String message;

  @override
  String toString() => 'DataSizeException: $message';
}

/// Exception thrown when data validation fails.
class DataValidationException implements Exception {
  const DataValidationException(this.message);
  final String message;

  @override
  String toString() => 'DataValidationException: $message';
}
