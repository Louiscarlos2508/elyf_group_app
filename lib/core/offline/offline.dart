/// Offline-first infrastructure for the ELYF Groupe application.
///
/// This library provides:
/// - Local data persistence with Isar database
/// - Automatic synchronization with Firebase
/// - Conflict resolution using `updated_at` timestamps
/// - Network connectivity monitoring
/// - Pending operations queue with retry logic
/// - Data sanitization and security
/// - Exponential backoff for retries
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
///
/// ## Security Features
///
/// - Input sanitization prevents injection attacks
/// - Sensitive fields are automatically removed from sync data
/// - Data size limits prevent DoS attacks
/// - ID validation ensures data integrity
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

// Security
export 'security/data_sanitizer.dart';
export 'security/secure_storage.dart';

// Sync handlers
export 'handlers/firebase_sync_handler.dart';

// Collections
export 'collections/enterprise_collection.dart';
export 'collections/expense_collection.dart';
export 'collections/product_collection.dart';
export 'collections/sale_collection.dart';
