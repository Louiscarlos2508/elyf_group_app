import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workmanager/workmanager.dart';

import '../../firebase_options.dart';
import 'drift_service.dart';
import 'connectivity_service.dart';
import 'sync_manager.dart';
import 'handlers/firebase_sync_handler.dart';
import 'sync_paths.dart';

/// Unique task name for periodic background synchronization.
const String syncTaskName = "com.elyf.app.sync_task";

/// Dispatcher for background tasks handled by Workmanager.
/// This must be a top-level function and annotated with @pragma('vm:entry-point').
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    developer.log('Background Sync worker started: $task', name: 'sync_worker');

    // Only handle our specific sync task
    if (task != syncTaskName && task != Workmanager.iOSBackgroundTask) {
      return Future.value(true);
    }

    try {
      // 1. Initialize Firebase
      // Workmanager runs in a separate isolate, so we need to re-initialize services.
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // 2. Initialize Drift
      final driftService = DriftService.instance;
      if (!driftService.isInitialized) {
        await driftService.initialize();
      }

      // 3. Initialize Connectivity (minimal)
      final connectivityService = ConnectivityService();
      await connectivityService.initialize();

      // 4. Initialize SyncManager
      final syncHandler = FirebaseSyncHandler(
        firestore: FirebaseFirestore.instance,
        collectionPaths: collectionPaths,
        driftService: driftService,
      );

      final syncManager = SyncManager(
        driftService: driftService,
        connectivityService: connectivityService,
        syncHandler: syncHandler,
      );

      await syncManager.initialize();

      // 5. Run sync
      // We only attempt to sync if we are online.
      if (connectivityService.currentStatus.isOnline) {
        final result = await syncManager.syncPendingOperations();
        
        developer.log(
          'Background Sync completed: ${result.success ? "Success" : "Failure (${result.message})"}',
          name: 'sync_worker',
        );
      } else {
        developer.log(
          'Background Sync skipped: Device is offline',
          name: 'sync_worker',
        );
      }

      // Cleanup to free resources in the background isolate
      await syncManager.dispose();
      await connectivityService.dispose();
      // DriftService is a singleton, but closing the DB is good practice in a short-lived isolate
      await driftService.close();

      return Future.value(true);
    } catch (e, stackTrace) {
      developer.log(
        'Background Sync failed with error: $e',
        name: 'sync_worker',
        error: e,
        stackTrace: stackTrace,
      );
      // Return false to indicate a failure and potentially trigger a retry by the OS
      return Future.value(false);
    }
  });
}
