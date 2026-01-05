import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'sync_status.dart';
import 'collections/enterprise_collection.dart';
import 'collections/sale_collection.dart';
import 'collections/product_collection.dart';
import 'collections/expense_collection.dart';

/// Service for managing the Isar database instance.
///
/// Handles initialization, migrations, and provides access to collections.
class IsarService {
  IsarService._();

  static IsarService? _instance;
  Isar? _isar;

  /// Singleton instance of the Isar service.
  static IsarService get instance {
    _instance ??= IsarService._();
    return _instance!;
  }

  /// The Isar database instance.
  ///
  /// Throws if accessed before initialization.
  Isar get isar {
    if (_isar == null) {
      throw StateError(
        'IsarService not initialized. Call initialize() first.',
      );
    }
    return _isar!;
  }

  /// Whether the database is initialized.
  bool get isInitialized => _isar != null;

  /// Current database version for migrations.
  static const int currentVersion = 1;

  /// Initializes the Isar database.
  ///
  /// Should be called once during app startup, typically in `bootstrap()`.
  Future<void> initialize() async {
    if (_isar != null) {
      developer.log(
        'Isar already initialized',
        name: 'offline.isar',
      );
      return;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = dir.path;

      developer.log(
        'Initializing Isar database at: $path',
        name: 'offline.isar',
      );

      _isar = await Isar.open(
        [
          // Sync infrastructure collections
          SyncMetadataSchema,
          SyncOperationSchema,
          // Business entity collections
          EnterpriseCollectionSchema,
          SaleCollectionSchema,
          SaleItemCollectionSchema,
          ProductCollectionSchema,
          ExpenseCollectionSchema,
        ],
        directory: path,
        name: 'elyf_offline',
        inspector: kDebugMode,
      );

      await _runMigrations();

      developer.log(
        'Isar database initialized successfully',
        name: 'offline.isar',
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to initialize Isar database',
        name: 'offline.isar',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Runs any necessary database migrations.
  Future<void> _runMigrations() async {
    // Get stored version (using sync metadata collection for meta info)
    // For simplicity, we assume first-time setup for now
    // In production, implement proper version tracking

    developer.log(
      'Database at version $currentVersion',
      name: 'offline.isar',
    );
  }

  /// Clears all data from the database.
  ///
  /// Use with caution - this is irreversible.
  Future<void> clearAll() async {
    await isar.writeTxn(() async {
      await isar.clear();
    });
    developer.log(
      'All Isar data cleared',
      name: 'offline.isar',
    );
  }

  /// Clears data for a specific enterprise.
  ///
  /// Used when switching tenants or logging out.
  Future<void> clearEnterpriseData(String enterpriseId) async {
    await isar.writeTxn(() async {
      // Clear sales for this enterprise
      await isar.saleCollections
          .filter()
          .enterpriseIdEqualTo(enterpriseId)
          .deleteAll();

      // Clear products for this enterprise
      await isar.productCollections
          .filter()
          .enterpriseIdEqualTo(enterpriseId)
          .deleteAll();

      // Clear expenses for this enterprise
      await isar.expenseCollections
          .filter()
          .enterpriseIdEqualTo(enterpriseId)
          .deleteAll();

      // Clear sync operations for this enterprise
      await isar.syncOperations
          .filter()
          .enterpriseIdEqualTo(enterpriseId)
          .deleteAll();
    });

    developer.log(
      'Cleared data for enterprise: $enterpriseId',
      name: 'offline.isar',
    );
  }

  /// Gets the count of pending sync operations.
  Future<int> getPendingSyncCount() async {
    return isar.syncOperations.count();
  }

  /// Gets database statistics for debugging.
  Future<Map<String, int>> getStats() async {
    return {
      'enterprises': await isar.enterpriseCollections.count(),
      'sales': await isar.saleCollections.count(),
      'products': await isar.productCollections.count(),
      'expenses': await isar.expenseCollections.count(),
      'syncMetadata': await isar.syncMetadatas.count(),
      'pendingOperations': await isar.syncOperations.count(),
    };
  }

  /// Closes the database connection.
  ///
  /// Should be called when the app is being disposed.
  Future<void> close() async {
    await _isar?.close();
    _isar = null;
    developer.log(
      'Isar database closed',
      name: 'offline.isar',
    );
  }

  /// Disposes the singleton instance.
  ///
  /// Used for testing or app shutdown.
  static Future<void> dispose() async {
    await _instance?.close();
    _instance = null;
  }
}
