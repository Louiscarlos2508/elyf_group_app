import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';

import 'package:elyf_groupe_app/core/offline/drift_service.dart';
import 'package:elyf_groupe_app/core/offline/sync_manager.dart';
import 'package:elyf_groupe_app/core/offline/connectivity_service.dart';
import 'package:elyf_groupe_app/features/gaz/data/repositories/gas_offline_repository.dart';
import '../../../../helpers/test_helpers.dart';

import 'gas_offline_repository_test.mocks.dart';

@GenerateMocks([DriftService, SyncManager, ConnectivityService])
void main() {
  group('GasOfflineRepository', () {
    // Note: Les tests d'intégration complets nécessitent une base Drift en mémoire
    // Pour l'instant, on teste la structure de base
    // Les tests d'intégration complets seront dans test/integration/

    test('repository should be instantiable', () {
      // Arrange
      final mockDriftService = MockDriftService();
      final mockSyncManager = MockSyncManager();
      final mockConnectivityService = MockConnectivityService();

      // Act
      final repository = GasOfflineRepository(
        driftService: mockDriftService,
        syncManager: mockSyncManager,
        connectivityService: mockConnectivityService,
        enterpriseId: TestIds.enterprise1,

      );

      // Assert
      expect(repository, isNotNull);
    });

    // Les tests CRUD complets nécessitent une base Drift en mémoire
    // et seront implémentés dans les tests d'intégration
  });
}
