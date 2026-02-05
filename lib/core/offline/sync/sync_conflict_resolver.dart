import 'dart:developer' as developer;

import '../../logging/app_logger.dart';

/// Strategy for resolving sync conflicts between local and remote data.
enum ConflictResolutionStrategy {
  /// Always use the server version (default for most cases)
  serverWins,
  
  /// Always use the local version
  localWins,
  
  /// Use the version with the most recent timestamp
  lastWriteWins,
  
  /// Merge both versions (field-by-field comparison)
  merge,
  
  /// Require manual resolution (throw exception)
  manual,
}

/// Result of a conflict resolution operation.
class ConflictResolution {
  const ConflictResolution({
    required this.resolvedData,
    required this.strategy,
    required this.wasConflict,
    this.conflictDetails,
  });

  final Map<String, dynamic> resolvedData;
  final ConflictResolutionStrategy strategy;
  final bool wasConflict;
  final String? conflictDetails;
}

/// Service for resolving conflicts during synchronization.
class SyncConflictResolver {
  SyncConflictResolver({
    this.defaultStrategy = ConflictResolutionStrategy.lastWriteWins,
    this.customStrategies = const {},
  });

  final ConflictResolutionStrategy defaultStrategy;
  final Map<String, ConflictResolutionStrategy> customStrategies;

  /// Resolves a conflict between local and server data.
  ConflictResolution resolve({
    required Map<String, dynamic> localData,
    required Map<String, dynamic> serverData,
    required String collectionName,
    ConflictResolutionStrategy? strategy,
  }) {
    // Determine which strategy to use
    final effectiveStrategy = strategy ??
        customStrategies[collectionName] ??
        defaultStrategy;

    // Check if there's actually a conflict
    final hasConflict = _detectConflict(localData, serverData);

    if (!hasConflict) {
      return ConflictResolution(
        resolvedData: serverData,
        strategy: effectiveStrategy,
        wasConflict: false,
      );
    }

    developer.log(
      'Conflict detected in $collectionName, using strategy: ${effectiveStrategy.name}',
      name: 'sync.conflict',
    );

    // Resolve based on strategy
    switch (effectiveStrategy) {
      case ConflictResolutionStrategy.serverWins:
        return ConflictResolution(
          resolvedData: serverData,
          strategy: effectiveStrategy,
          wasConflict: true,
          conflictDetails: 'Server version chosen',
        );

      case ConflictResolutionStrategy.localWins:
        return ConflictResolution(
          resolvedData: localData,
          strategy: effectiveStrategy,
          wasConflict: true,
          conflictDetails: 'Local version chosen',
        );

      case ConflictResolutionStrategy.lastWriteWins:
        return _resolveLastWriteWins(localData, serverData, effectiveStrategy);

      case ConflictResolutionStrategy.merge:
        return _resolveMerge(localData, serverData, effectiveStrategy);

      case ConflictResolutionStrategy.manual:
        throw SyncConflictException(
          'Manual resolution required for $collectionName',
          localData: localData,
          serverData: serverData,
        );
    }
  }

  /// Detects if there's a conflict between local and server data.
  bool _detectConflict(
    Map<String, dynamic> localData,
    Map<String, dynamic> serverData,
  ) {
    // Compare updatedAt timestamps
    final localUpdatedAt = _parseTimestamp(localData['updatedAt']);
    final serverUpdatedAt = _parseTimestamp(serverData['updatedAt']);

    if (localUpdatedAt == null || serverUpdatedAt == null) {
      return false; // Can't determine conflict without timestamps
    }

    // If timestamps are different, there might be a conflict
    if (localUpdatedAt != serverUpdatedAt) {
      // Check if the data is actually different
      return !_areDataEqual(localData, serverData);
    }

    return false;
  }

  /// Resolves conflict using last-write-wins strategy.
  ConflictResolution _resolveLastWriteWins(
    Map<String, dynamic> localData,
    Map<String, dynamic> serverData,
    ConflictResolutionStrategy strategy,
  ) {
    final localUpdatedAt = _parseTimestamp(localData['updatedAt']);
    final serverUpdatedAt = _parseTimestamp(serverData['updatedAt']);

    if (localUpdatedAt == null && serverUpdatedAt == null) {
      // No timestamps, default to server
      return ConflictResolution(
        resolvedData: serverData,
        strategy: strategy,
        wasConflict: true,
        conflictDetails: 'No timestamps, defaulting to server',
      );
    }

    if (localUpdatedAt == null) {
      return ConflictResolution(
        resolvedData: serverData,
        strategy: strategy,
        wasConflict: true,
        conflictDetails: 'Local has no timestamp',
      );
    }

    if (serverUpdatedAt == null) {
      return ConflictResolution(
        resolvedData: localData,
        strategy: strategy,
        wasConflict: true,
        conflictDetails: 'Server has no timestamp',
      );
    }

    // Compare timestamps
    final useLocal = localUpdatedAt.isAfter(serverUpdatedAt);
    return ConflictResolution(
      resolvedData: useLocal ? localData : serverData,
      strategy: strategy,
      wasConflict: true,
      conflictDetails: useLocal
          ? 'Local is newer (${localUpdatedAt.toIso8601String()})'
          : 'Server is newer (${serverUpdatedAt.toIso8601String()})',
    );
  }

  /// Resolves conflict by merging both versions.
  ConflictResolution _resolveMerge(
    Map<String, dynamic> localData,
    Map<String, dynamic> serverData,
    ConflictResolutionStrategy strategy,
  ) {
    final merged = Map<String, dynamic>.from(serverData);
    final conflicts = <String>[];

    // Merge fields from local that are newer or missing in server
    for (final entry in localData.entries) {
      final key = entry.key;
      final localValue = entry.value;

      // Skip metadata fields
      if (key == 'id' || key == 'localId' || key == 'remoteId') {
        continue;
      }

      // If server doesn't have this field, use local
      if (!serverData.containsKey(key)) {
        merged[key] = localValue;
        conflicts.add('$key: added from local');
        continue;
      }

      final serverValue = serverData[key];

      // If values are different, prefer the one with newer timestamp
      if (localValue != serverValue) {
        // For now, keep server value (could be enhanced with field-level timestamps)
        conflicts.add('$key: kept server value');
      }
    }

    return ConflictResolution(
      resolvedData: merged,
      strategy: strategy,
      wasConflict: conflicts.isNotEmpty,
      conflictDetails: conflicts.isEmpty
          ? null
          : 'Merged ${conflicts.length} fields: ${conflicts.join(', ')}',
    );
  }

  /// Parses a timestamp from various formats.
  DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        AppLogger.warning(
          'Failed to parse timestamp: $value',
          name: 'sync.conflict',
          error: e,
        );
        return null;
      }
    }
    return null;
  }

  /// Checks if two data maps are equal (ignoring timestamps).
  bool _areDataEqual(
    Map<String, dynamic> data1,
    Map<String, dynamic> data2,
  ) {
    // Create copies without timestamp fields
    final map1 = Map<String, dynamic>.from(data1)
      ..remove('updatedAt')
      ..remove('createdAt')
      ..remove('localUpdatedAt');
    final map2 = Map<String, dynamic>.from(data2)
      ..remove('updatedAt')
      ..remove('createdAt')
      ..remove('localUpdatedAt');

    // Compare keys
    if (map1.keys.length != map2.keys.length) return false;
    if (!map1.keys.every(map2.containsKey)) return false;

    // Compare values
    for (final key in map1.keys) {
      if (map1[key] != map2[key]) return false;
    }

    return true;
  }
}

/// Exception thrown when manual conflict resolution is required.
class SyncConflictException implements Exception {
  SyncConflictException(
    this.message, {
    required this.localData,
    required this.serverData,
  });

  final String message;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> serverData;

  @override
  String toString() => 'SyncConflictException: $message';
}
