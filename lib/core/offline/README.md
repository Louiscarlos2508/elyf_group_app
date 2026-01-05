# Core › Offline

This module implements offline-first data persistence using Isar database with automatic synchronization to Firebase.

## Security Features

### Data Sanitization
- All string inputs are sanitized to prevent injection attacks
- Dangerous characters (`<`, `>`, `"`, control characters) are escaped
- Maximum string length enforced (10,000 characters by default)
- Maximum JSON size enforced (1MB by default)

### Sensitive Data Protection
- Sensitive fields (passwords, tokens, etc.) are automatically removed before storage
- Configurable list of sensitive field names
- Fields containing: `password`, `token`, `secret`, `apiKey`, `pin`, `cvv`, `ssn` are filtered

### ID Validation
- All IDs are validated against alphanumeric pattern
- Maximum ID length of 100 characters
- Invalid IDs are rejected with clear error messages

### Retry Security
- Maximum retry attempts prevent infinite loops (default: 5)
- Exponential backoff prevents server overload
- Jitter added to prevent thundering herd
- Old operations cleaned up after 72 hours

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        UI Layer                                  │
│   (Widgets use Riverpod providers for reactive updates)         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Providers Layer                              │
│   isOnlineProvider, syncProgressProvider, etc.                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Repository Layer                                │
│   OfflineRepository<T> - base class for offline-first repos     │
└─────────────────────────────────────────────────────────────────┘
                    │                    │
                    ▼                    ▼
┌──────────────────────────┐  ┌──────────────────────────┐
│     Isar Database        │  │     SyncManager          │
│  (Local persistence)     │  │  (Background sync)       │
└──────────────────────────┘  └──────────────────────────┘
                                         │
                                         ▼
                              ┌──────────────────────────┐
                              │      Firebase            │
                              │   (Remote backend)       │
                              └──────────────────────────┘
```

## Files Structure

- `isar_service.dart` – Database initialization, migrations, and instance management
- `sync_manager.dart` – Offline-first sync strategy with `updated_at` conflict resolution
- `connectivity_service.dart` – Network connectivity monitoring
- `sync_status.dart` – Sync metadata and pending operations models
- `offline_repository.dart` – Base class for offline-enabled repositories
- `providers.dart` – Riverpod providers for offline state
- `collections/` – Isar collection models for each entity type
  - `enterprise_collection.dart`
  - `product_collection.dart`
  - `sale_collection.dart`
  - `expense_collection.dart`

## Usage

### 1. Initialization (in bootstrap.dart)

```dart
import 'package:elyf_groupe_app/core/offline/offline.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Isar database
  await IsarService.instance.initialize();
  
  // Initialize connectivity service
  final connectivityService = ConnectivityService();
  await connectivityService.initialize();
}
```

### 2. Check Connectivity Status

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    
    return Icon(
      isOnline ? Icons.cloud_done : Icons.cloud_off,
      color: isOnline ? Colors.green : Colors.grey,
    );
  }
}
```

### 3. Show Pending Sync Count

```dart
class SyncBadge extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(pendingSyncCountProvider);
    
    return pendingCount.when(
      data: (count) => count > 0 
          ? Badge(label: Text('$count'))
          : const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
```

### 4. Trigger Manual Sync

```dart
class SyncButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSyncing = ref.watch(isSyncingProvider);
    
    return ElevatedButton(
      onPressed: isSyncing 
          ? null 
          : () async {
              final actions = ref.read(syncActionsProvider.notifier);
              final result = await actions.triggerSync();
              // Handle result...
            },
      child: isSyncing 
          ? const CircularProgressIndicator()
          : const Text('Sync Now'),
    );
  }
}
```

### 5. Create an Offline-Enabled Repository

```dart
class ProductOfflineRepository extends OfflineRepository<Product> {
  ProductOfflineRepository({
    required super.isarService,
    required super.syncManager,
    required super.connectivityService,
  });

  @override
  String get collectionName => 'products';

  @override
  Product fromMap(Map<String, dynamic> map) => Product.fromMap(map);

  @override
  Map<String, dynamic> toMap(Product entity) => entity.toMap();

  @override
  String getLocalId(Product entity) => entity.localId;

  @override
  String? getRemoteId(Product entity) => entity.id;

  @override
  String? getEnterpriseId(Product entity) => entity.enterpriseId;

  @override
  Future<void> saveToLocal(Product entity) async {
    final collection = ProductCollection.fromMap(
      toMap(entity),
      enterpriseId: entity.enterpriseId,
      moduleType: 'boutique',
    );
    
    await isarService.isar.writeTxn(() async {
      await isarService.isar.productCollections.put(collection);
    });
  }

  @override
  Future<void> deleteFromLocal(Product entity) async {
    await isarService.isar.writeTxn(() async {
      await isarService.isar.productCollections
          .filter()
          .remoteIdEqualTo(entity.id)
          .deleteAll();
    });
  }

  @override
  Future<Product?> getByLocalId(String localId) async {
    final collection = await isarService.isar.productCollections
        .filter()
        .remoteIdEqualTo(localId)
        .findFirst();
    
    return collection != null ? Product.fromMap(collection.toMap()) : null;
  }

  @override
  Future<List<Product>> getAllForEnterprise(String enterpriseId) async {
    final collections = await isarService.isar.productCollections
        .filter()
        .enterpriseIdEqualTo(enterpriseId)
        .findAll();
    
    return collections.map((c) => Product.fromMap(c.toMap())).toList();
  }
}
```

## Sync Strategy

### Offline-First Principle

1. **Write locally first**: All data modifications are saved to Isar immediately
2. **Queue for sync**: Operations are queued in `SyncOperation` collection
3. **Background sync**: When online, pending operations are synced automatically
4. **Conflict resolution**: Uses `updated_at` timestamp (last write wins)

### Conflict Resolution

The `ConflictResolver` class supports multiple strategies:

- `serverWins` - Server data always wins
- `clientWins` - Client data always wins  
- `lastWriteWins` - Most recent `updated_at` wins (default)
- `merge` - Deep merge with local changes on top of server data

### Sync Queue Priority

Operations are processed by priority:
- Delete operations: priority 50 (highest)
- Create/Update operations: priority 100

## Running Code Generation

After modifying Isar collections, run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Database Schema

### SyncMetadata

Tracks sync state for each entity:

| Field | Type | Description |
|-------|------|-------------|
| collectionName | String | Entity type (e.g., "products") |
| localId | String | Local identifier |
| remoteId | String? | Firebase document ID |
| syncState | SyncState | Current sync status |
| localUpdatedAt | DateTime | Last local modification |
| remoteUpdatedAt | DateTime? | Last server modification |
| syncAttempts | int | Retry count |
| lastError | String? | Last sync error |

### SyncOperation

Pending operations queue:

| Field | Type | Description |
|-------|------|-------------|
| operationType | String | create, update, delete |
| collectionName | String | Entity type |
| localId | String | Local identifier |
| remoteId | String? | Firebase document ID |
| data | String | JSON payload |
| priority | int | Processing priority |
| retryCount | int | Retry attempts |
| enterpriseId | String? | Tenant identifier |

## Best Practices

1. **Always use local IDs**: Generate local IDs for new entities before saving
2. **Handle offline gracefully**: Show appropriate UI indicators
3. **Don't block on sync**: Let sync happen in background
4. **Test offline scenarios**: Use airplane mode during development
5. **Monitor pending queue**: Alert users if queue grows large

## Security Best Practices

### 1. Never Store Sensitive Data Locally

```dart
// ❌ BAD: Storing sensitive data
await repo.save(User(
  id: 'user123',
  password: 'secret123', // This will be filtered out
));

// ✅ GOOD: Store only non-sensitive data locally
await repo.save(User(
  id: 'user123',
  name: 'John Doe',
  email: 'john@example.com',
));
```

### 2. Validate All Input

```dart
// The sync manager validates automatically, but for extra safety:
if (!DataSanitizer.isValidId(userId)) {
  throw ArgumentError('Invalid user ID');
}
```

### 3. Configure Sync Appropriately

```dart
final syncManager = SyncManager(
  isarService: isarService,
  connectivityService: connectivityService,
  config: const SyncConfig(
    maxRetryAttempts: 5,        // Prevent infinite retries
    maxOperationAgeHours: 72,   // Clean up old operations
    operationTimeoutMs: 30000,  // Prevent hanging operations
    batchSize: 50,              // Limit batch size
  ),
);
```

### 4. Handle Errors Securely

```dart
try {
  await syncManager.queueCreate(...);
} on DataValidationException catch (e) {
  // Log sanitized error, don't expose details to user
  developer.log('Validation failed', name: 'sync', error: e);
  showErrorMessage('Invalid data. Please try again.');
} on DataSizeException catch (e) {
  showErrorMessage('Data too large. Please reduce content.');
}
```

### 5. Clear Data on Logout

```dart
Future<void> logout() async {
  // Clear all offline data for the current enterprise
  await isarService.clearEnterpriseData(currentEnterpriseId);

  // Or clear everything if needed
  await isarService.clearAll();
}
```

## Sync Configuration

| Parameter | Default | Description |
|-----------|---------|-------------|
| `maxRetryAttempts` | 5 | Maximum retries before giving up |
| `baseRetryDelayMs` | 1000 | Base delay for exponential backoff |
| `maxRetryDelayMs` | 60000 | Maximum delay between retries |
| `syncIntervalMinutes` | 5 | Automatic sync interval |
| `operationTimeoutMs` | 30000 | Individual operation timeout |
| `maxOperationAgeHours` | 72 | Auto-cleanup threshold |
| `batchSize` | 50 | Operations per sync batch |
