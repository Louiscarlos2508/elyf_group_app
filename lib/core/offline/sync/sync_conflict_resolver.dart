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
  const SyncConflictResolver({
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

    AppLogger.debug(
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
    var useLocal = localUpdatedAt.isAfter(serverUpdatedAt);
    
    // Safety check: if local has a deletion and server doesn't, 
    // favor local even if server is slightly newer (clock drift protection)
    // unless server is newer by more than 5 seconds.
    final localIsDeleted = localData['deletedAt'] != null;
    final serverIsDeleted = serverData['deletedAt'] != null;
    
    if (localIsDeleted && !serverIsDeleted) {
      final driftDifference = serverUpdatedAt.difference(localUpdatedAt).inSeconds;
      if (driftDifference >= 0 && driftDifference < 5) {
        useLocal = true;
        AppLogger.debug(
          'Conflict resolution: Favoring local deletion over slightly newer server version (${driftDifference}s diff)',
          name: 'sync.conflict',
        );
      }
    }

    return ConflictResolution(
      resolvedData: useLocal ? localData : serverData,
      strategy: strategy,
      wasConflict: true,
      conflictDetails: useLocal
          ? 'Local is newer or prioritized (${localUpdatedAt.toIso8601String()})'
          : 'Server is newer (${serverUpdatedAt.toIso8601String()})',
    );
  }

  /// Resolves conflict by merging both versions.
  ConflictResolution _resolveMerge(
    Map<String, dynamic> localData,
    Map<String, dynamic> serverData,
    ConflictResolutionStrategy strategy,
  ) {
    final localUpdatedAt = _parseTimestamp(localData['updatedAt']);
    final serverUpdatedAt = _parseTimestamp(serverData['updatedAt']);

    final result = _recursiveMerge(
      localData,
      serverData,
      localUpdatedAt,
      serverUpdatedAt,
    );

    return ConflictResolution(
      resolvedData: result.mergedData,
      strategy: strategy,
      wasConflict: result.conflicts.isNotEmpty,
      conflictDetails: result.conflicts.isEmpty
          ? null
          : 'Merged with ${result.conflicts.length} conflict(s): ${result.conflicts.take(5).join(', ')}${result.conflicts.length > 5 ? '...' : ''}',
    );
  }

  /// Recursively merges two maps using timestamps to resolve conflicts.
  _MergeResult _recursiveMerge(
    Map<String, dynamic> local,
    Map<String, dynamic> server,
    DateTime? localTime,
    DateTime? serverTime, [
    int depth = 0,
  ]) {
    if (depth > 10) {
      // Safety limit for recursion
      return _MergeResult(server, ['Max recursion depth reached, using server value']);
    }

    final merged = Map<String, dynamic>.from(server);
    final conflicts = <String>[];

    // Identify all unique keys
    final allKeys = {...local.keys, ...server.keys};

    for (final key in allKeys) {
      // Skip metadata fields at top level
      if (depth == 0 && (key == 'id' || key == 'localId' || key == 'remoteId')) {
        continue;
      }

      final inLocal = local.containsKey(key);
      final inServer = server.containsKey(key);

      if (inLocal && !inServer) {
        // Only in local: Add to merged
        merged[key] = local[key];
        conflicts.add('$key: added from local');
        continue;
      }

      if (!inLocal && inServer) {
        // Only in server: Keep server value (default)
        continue;
      }

      // In both: Compare values
      final localVal = local[key];
      final serverVal = server[key];

      if (_isEqual(localVal, serverVal)) {
        continue;
      }

      // Values are different
      if (localVal is Map<String, dynamic> && serverVal is Map<String, dynamic>) {
        // Recurse for nested maps
        final nestedResult = _recursiveMerge(
          localVal,
          serverVal,
          localTime,
          serverTime,
          depth + 1,
        );
        merged[key] = nestedResult.mergedData;
        conflicts.addAll(nestedResult.conflicts.map((c) => '$key.$c'));
      } else {
        // Simple value conflict: use last-write-wins if possible
        bool useLocal = false;
        if (localTime != null && serverTime != null) {
          useLocal = localTime.isAfter(serverTime);
        }

        if (useLocal) {
          merged[key] = localVal;
          conflicts.add('$key: local wins (newer)');
        } else {
          merged[key] = serverVal;
          conflicts.add('$key: server wins (newer or default)');
        }
      }
    }

    return _MergeResult(merged, conflicts);
  }

  /// Deep equality check for various types.
  bool _isEqual(dynamic a, dynamic b) {
    if (identical(a, b)) return true;
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key) || !_isEqual(a[key], b[key])) return false;
      }
      return true;
    }
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (int i = 0; i < a.length; i++) {
        if (!_isEqual(a[i], b[i])) return false;
      }
      return true;
    }
    return a == b;
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
      if (!_isEqual(map1[key], map2[key])) return false;
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

/// Internal class to hold recursive merge results.
class _MergeResult {
  _MergeResult(this.mergedData, this.conflicts);
  final Map<String, dynamic> mergedData;
  final List<String> conflicts;
}
