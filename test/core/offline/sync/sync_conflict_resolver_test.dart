import 'package:flutter_test/flutter_test.dart';
import 'package:elyf_groupe_app/core/offline/sync/sync_conflict_resolver.dart';

void main() {
  late SyncConflictResolver resolver;

  setUp(() {
    resolver = SyncConflictResolver();
  });

  group('SyncConflictResolver - Basic Strategies', () {
    final localData = {'id': '1', 'name': 'Local', 'updatedAt': '2023-01-01T12:00:00Z'};
    final serverData = {'id': '1', 'name': 'Server', 'updatedAt': '2023-01-01T12:00:05Z'};

    test('serverWins returns server data', () {
      final result = resolver.resolve(
        localData: localData,
        serverData: serverData,
        collectionName: 'test',
        strategy: ConflictResolutionStrategy.serverWins,
      );
      expect(result.resolvedData['name'], 'Server');
      expect(result.wasConflict, isTrue);
    });

    test('localWins returns local data', () {
      final result = resolver.resolve(
        localData: localData,
        serverData: serverData,
        collectionName: 'test',
        strategy: ConflictResolutionStrategy.localWins,
      );
      expect(result.resolvedData['name'], 'Local');
    });

    test('lastWriteWins uses timestamps', () {
      final result = resolver.resolve(
        localData: localData,
        serverData: serverData,
        collectionName: 'test',
        strategy: ConflictResolutionStrategy.lastWriteWins,
      );
      expect(result.resolvedData['name'], 'Server'); // Server is newer
    });
  });

  group('SyncConflictResolver - Merge Strategy', () {
    test('merges simple fields using timestamps', () {
      final localData = {
        'id': '1',
        'field1': 'local',
        'field2': 'local',
        'updatedAt': '2023-01-01T12:00:10Z',
      };
      final serverData = {
        'id': '1',
        'field1': 'server',
        'field3': 'server',
        'updatedAt': '2023-01-01T12:00:00Z',
      };

      final result = resolver.resolve(
        localData: localData,
        serverData: serverData,
        collectionName: 'test',
        strategy: ConflictResolutionStrategy.merge,
      );

      final merged = result.resolvedData;
      expect(merged['field1'], 'local'); // Local is newer
      expect(merged['field2'], 'local'); // Only in local
      expect(merged['field3'], 'server'); // Only in server
      expect(result.wasConflict, isTrue);
    });

    test('recursively merges nested maps', () {
      final localData = {
        'id': '1',
        'nested': {
          'l1': 'local',
          'conflict': 'local_wins',
        },
        'updatedAt': '2023-01-01T12:00:10Z',
      };
      final serverData = {
        'id': '1',
        'nested': {
          's1': 'server',
          'conflict': 'server_old',
        },
        'updatedAt': '2023-01-01T12:00:00Z',
      };

      final result = resolver.resolve(
        localData: localData,
        serverData: serverData,
        collectionName: 'test',
        strategy: ConflictResolutionStrategy.merge,
      );

      final mergedNested = result.resolvedData['nested'] as Map;
      expect(mergedNested['l1'], 'local');
      expect(mergedNested['s1'], 'server');
      expect(mergedNested['conflict'], 'local_wins');
    });

    test('handles list deep equality', () {
      final localData = {
        'id': '1',
        'list': [1, 2, 3],
        'updatedAt': '2023-01-01T12:00:10Z',
      };
      final serverData = {
        'id': '1',
        'list': [1, 2, 3],
        'updatedAt': '2023-01-01T12:00:00Z',
      };

      final result = resolver.resolve(
        localData: localData,
        serverData: serverData,
        collectionName: 'test',
        strategy: ConflictResolutionStrategy.merge,
      );

      expect(result.wasConflict, isFalse); // No real conflict even if timestamps differ
    });
  });
}
