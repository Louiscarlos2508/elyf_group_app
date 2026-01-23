import 'dart:developer' as developer;
import 'dart:convert';

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import 'optimized_queries.dart';

/// Offline-first repository for User entities.
///
/// Note: Users are global (not enterprise-specific), so enterpriseId is not used.
class UserOfflineRepository extends OfflineRepository<User>
    implements UserRepository {
  UserOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
  });

  @override
  String get collectionName => 'users';

  @override
  User fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String? ?? map['localId'] as String,
      firstName: map['firstName'] as String,
      lastName: map['lastName'] as String,
      username: map['username'] as String,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  @override
  Map<String, dynamic> toMap(User entity) {
    return {
      'id': entity.id,
      'firstName': entity.firstName,
      'lastName': entity.lastName,
      'username': entity.username,
      'email': entity.email,
      'phone': entity.phone,
      'isActive': entity.isActive,
      'createdAt': entity.createdAt?.toIso8601String(),
      'updatedAt': entity.updatedAt?.toIso8601String(),
    };
  }

  @override
  String getLocalId(User entity) {
    if (entity.id.startsWith('local_')) {
      return entity.id;
    }
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(User entity) {
    if (!entity.id.startsWith('local_')) {
      return entity.id;
    }
    return null;
  }

  @override
  String? getEnterpriseId(User entity) => null;
  // ✅ Users are global - not tied to a specific enterprise
  // ✅ Assignment to enterprises is done via EnterpriseModuleUser

  @override
  Future<void> saveToLocal(User entity) async {
    try {
      // Utiliser findExistingLocalId pour éviter les duplications
      final existingLocalId = await findExistingLocalId(
        entity,
        moduleType: 'administration',
      );
      final localId = existingLocalId ?? getLocalId(entity);
      final remoteId = getRemoteId(entity);
      final map = toMap(entity)..['localId'] = localId;
      
      developer.log(
        'Sauvegarde User: id=${entity.id}, localId=$localId, remoteId=$remoteId, existingLocalId=$existingLocalId',
        name: 'offline.repository.user',
      );
      
      await driftService.records.upsert(
        collectionName: collectionName,
        localId: localId,
        remoteId: remoteId,
        enterpriseId: 'global',
        // ✅ Users are stored globally (not tied to a specific enterprise)
        // ✅ Assignment to enterprises/modules is done via EnterpriseModuleUser
        moduleType: 'administration',
        dataJson: jsonEncode(map),
        localUpdatedAt: DateTime.now(),
      );
      
      developer.log(
        '✅ User sauvegardé avec succès: id=${entity.id}, localId=$localId',
        name: 'offline.repository.user',
      );
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        '❌ Error saving user to local Drift database: ${appException.message}',
        name: 'offline.repository.user',
        error: e,
        stackTrace: stackTrace,
      );
      // Rethrow pour que l'appelant puisse gérer l'erreur
      rethrow;
    }
  }

  @override
  Future<void> deleteFromLocal(User entity) async {
    final localId = getLocalId(entity);
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: 'global',
      moduleType: 'administration',
    );
  }

  @override
  Future<User?> getByLocalId(String localId) async {
    final record = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: 'global',
      moduleType: 'administration',
    );
    if (record == null) return null;
    final map = jsonDecode(record.dataJson) as Map<String, dynamic>;
    return fromMap(map);
  }

  @override
  Future<List<User>> getAllForEnterprise(String enterpriseId) {
    // Users are global, not enterprise-specific
    return getAllUsers();
  }

  // UserRepository implementation
  @override
  Future<List<User>> getAllUsers() async {
    try {
      final records = await driftService.records.listForEnterprise(
        collectionName: collectionName,
        enterpriseId: 'global',
        moduleType: 'administration',
      );
      return records.map((record) {
        final map = jsonDecode(record.dataJson) as Map<String, dynamic>;
        return fromMap(map);
      }).toList();
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error fetching users from offline storage: ${appException.message}',
        name: 'admin.user.repository',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  @override
  Future<({List<User> users, int totalCount})> getUsersPaginated({
    int page = 0,
    int limit = 50,
  }) async {
    try {
      // Validate and clamp pagination parameters
      final validated = OptimizedQueries.validatePagination(
        page: page,
        limit: limit,
      );
      final offset = OptimizedQueries.calculateOffset(
        validated.page,
        validated.limit,
      );

      // Get paginated records using LIMIT/OFFSET at Drift level
      final records = await driftService.records.listForEnterprisePaginated(
        collectionName: collectionName,
        enterpriseId: 'global',
        moduleType: 'administration',
        limit: validated.limit,
        offset: offset,
      );

      // Get total count for pagination info
      final totalCount = await driftService.records.countForEnterprise(
        collectionName: collectionName,
        enterpriseId: 'global',
        moduleType: 'administration',
      );

      final users = records.map<User>((record) {
        final map = jsonDecode(record.dataJson) as Map<String, dynamic>;
        return fromMap(map);
      }).toList();

      return (users: users, totalCount: totalCount);
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error fetching paginated users from offline storage: ${appException.message}',
        name: 'admin.user.repository',
        error: e,
        stackTrace: stackTrace,
      );
      return (users: <User>[], totalCount: 0);
    }
  }

  @override
  Future<User?> getUserById(String id) async {
    try {
      // Try to find by remote ID first
      final record = await driftService.records.findByRemoteId(
        collectionName: collectionName,
        remoteId: id,
        enterpriseId: 'global',
        moduleType: 'administration',
      );
      if (record != null) {
        final map = jsonDecode(record.dataJson) as Map<String, dynamic>;
        return fromMap(map);
      }
      // Try by local ID
      return await getByLocalId(id);
    } catch (e) {
      developer.log(
        'Error fetching user by ID: $id',
        name: 'admin.user.repository',
        error: e,
      );
      return null;
    }
  }

  @override
  Future<List<User>> searchUsers(String query) async {
    if (query.isEmpty) {
      return [];
    }

    // Optimize: Load all users once and filter in memory
    // In production, this should use SQL LIKE queries with Drift
    final allUsers = await getAllUsers();
    final lowerQuery = query.toLowerCase();

    // Use optimized query limit
    const maxResults = 100;
    final results = <User>[];

    // Early return optimization with limit
    for (final user in allUsers) {
      if (results.length >= maxResults) {
        break; // Early exit when limit reached
      }

      if (user.firstName.toLowerCase().contains(lowerQuery) ||
          user.lastName.toLowerCase().contains(lowerQuery) ||
          user.username.toLowerCase().contains(lowerQuery) ||
          (user.email?.toLowerCase().contains(lowerQuery) ?? false)) {
        results.add(user);
      }
    }
    return results;
  }

  @override
  Future<User> createUser(User user) async {
    try {
      await save(user);
      final createdUser = await getUserById(user.id);
      if (createdUser == null) {
        // Si l'utilisateur n'a pas pu être récupéré depuis Drift,
        // mais qu'il existe dans Firestore, retourner l'utilisateur original
        // Il sera récupéré lors de la prochaine synchronisation
        developer.log(
          'User saved but not found in local database. User exists in Firestore, will be synced: ${user.id}',
          name: 'offline.repository.user',
        );
        // Retourner l'utilisateur avec les timestamps mis à jour
        return user.copyWith(
          createdAt: user.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      return createdUser;
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.warning(
        'Error creating user in local database (user may exist in Firestore): ${appException.message}',
        name: 'offline.repository.user',
        error: e,
        stackTrace: stackTrace,
      );
      // Si la sauvegarde locale échoue, retourner l'utilisateur quand même
      // Il sera récupéré depuis Firestore lors de la prochaine synchronisation
      // ou lors d'un refresh manuel
      return user.copyWith(
        createdAt: user.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<User> updateUser(User user) async {
    await save(user);
    final updatedUser = await getUserById(user.id);
    if (updatedUser == null) {
      throw StorageException(
        'Failed to update user',
        'USER_UPDATE_FAILED',
      );
    }
    return updatedUser;
  }

  @override
  Future<void> deleteUser(String id) async {
    final user = await getUserById(id);
    if (user != null) {
      await delete(user);
    }
  }

  @override
  Future<User?> getUserByUsername(String username) async {
    // Optimize: Direct query instead of loading all users
    final allUsers = await getAllUsers();
    try {
      // Use iterator for early exit optimization
      for (final user in allUsers) {
        if (user.username == username) {
          return user;
        }
      }
      return null;
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.warning(
        'Error in getUserByUsername: ${appException.message}',
        name: 'admin.user.repository',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  Future<void> toggleUserStatus(String userId, bool isActive) async {
    final user = await getUserById(userId);
    if (user != null) {
      final updatedUser = user.copyWith(
        isActive: isActive,
        updatedAt: DateTime.now(),
      );
      await save(updatedUser);
    }
  }

  @override
  Future<User> ensureDefaultAdminExists({
    required String adminId,
    required String adminEmail,
    String? adminPasswordHash,
  }) async {
    final existingUser = await getUserById(adminId);
    if (existingUser != null) {
      return existingUser;
    }

    // Create default admin user
    final adminUser = User(
      id: adminId,
      firstName: 'Admin',
      lastName: 'System',
      username: 'admin',
      email: adminEmail,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await save(adminUser);
    final createdUser = await getUserById(adminId);
    if (createdUser == null) {
      throw StorageException(
        'Failed to create default admin user',
        'ADMIN_CREATION_FAILED',
      );
    }
    return createdUser;
  }
}
