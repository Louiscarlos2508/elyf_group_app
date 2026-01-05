/// Offline-first infrastructure for the ELYF Groupe application.
///
/// This library provides:
/// - Local data persistence with Isar database
/// - Automatic synchronization with Firebase
/// - Conflict resolution using `updated_at` timestamps
/// - Network connectivity monitoring
/// - Pending operations queue with retry logic
///
/// ## Quick Start
///
/// 1. Initialize in bootstrap:
/// ```dart
/// await IsarService.instance.initialize();
/// ```
///
/// 2. Use providers in your widgets:
/// ```dart
/// final isOnline = ref.watch(isOnlineProvider);
/// final pendingCount = ref.watch(pendingSyncCountProvider);
/// ```
///
/// 3. Create offline-enabled repositories:
/// ```dart
/// class MyRepository extends OfflineRepository<MyEntity> {
///   @override
///   String get collectionName => 'my_entities';
///   // ... implement abstract methods
/// }
/// ```
library offline;

// Core services
export 'connectivity_service.dart';
export 'isar_service.dart';
export 'sync_manager.dart';

// Data models
export 'sync_status.dart';

// Repository base
export 'offline_repository.dart';

// Riverpod providers
export 'providers.dart';

// Collections
export 'collections/enterprise_collection.dart';
export 'collections/expense_collection.dart';
export 'collections/product_collection.dart';
export 'collections/sale_collection.dart';

// Widgets
export 'widgets/sync_status_indicator.dart';
