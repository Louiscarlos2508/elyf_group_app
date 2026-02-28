import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';

/// Firestore-based repository for user operations
/// Online-only with pagination and search support
class UserFirestoreRepository implements UserRepository {
  UserFirestoreRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Future<List<User>> getAllUsers() async {
    try {
      final snapshot = await _users.get();
      return snapshot.docs
          .map((doc) => User.fromMap(doc.data()))
          .toList();
    } catch (e) {
      // Return empty list on permission denied
      return [];
    }
  }

  @override
  Stream<List<User>> watchAllUsers() {
    return _users.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => User.fromMap(doc.data()))
          .toList(),
    ).onErrorReturn(<User>[]);
  }

  @override
  Future<({List<User> users, int totalCount})> getUsersPaginated({
    int page = 0,
    int limit = 50,
  }) async {
    // Validate pagination parameters
    final validatedPage = page.clamp(0, 1000);
    final validatedLimit = limit.clamp(1, 100);
    
    // Get total count
    final countSnapshot = await _users.count().get();
    final totalCount = countSnapshot.count ?? 0;
    
    // Firestore doesn't have offset, use in-memory pagination
    // For production, implement cursor-based pagination with startAfter
    final allUsers = await getAllUsers();
    final startIndex = validatedPage * validatedLimit;
    final endIndex = (startIndex + validatedLimit).clamp(0, allUsers.length);
    
    final users = startIndex < allUsers.length
        ? allUsers.sublist(startIndex, endIndex)
        : <User>[];
    
    return (users: users, totalCount: totalCount);
  }

  @override
  Future<User?> getUserById(String userId) async {
    final doc = await _users.doc(userId).get();
    if (!doc.exists) return null;
    return User.fromMap(doc.data()!);
  }

  @override
  Future<User?> getUserByUsername(String username) async {
    final snapshot = await _users
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) return null;
    return User.fromMap(snapshot.docs.first.data());
  }

  @override
  Future<List<User>> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      return getAllUsers();
    }
    
    final lowerQuery = query.toLowerCase();
    
    // Firestore doesn't support case-insensitive search or OR queries natively
    // We'll fetch all users and filter in memory
    // For production, consider using Algolia or similar for better search
    final allUsers = await getAllUsers();
    
    return allUsers.where((user) {
      final fullName = '${user.firstName} ${user.lastName}'.toLowerCase();
      final username = user.username.toLowerCase();
      final email = user.email?.toLowerCase() ?? '';
      
      return fullName.contains(lowerQuery) ||
          username.contains(lowerQuery) ||
          email.contains(lowerQuery);
    }).toList();
  }

  @override
  Future<User> createUser(User user) async {
    final userWithTimestamps = user.copyWith(
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await _users.doc(user.id).set(userWithTimestamps.toMap());
    return userWithTimestamps;
  }

  @override
  Future<User> updateUser(User user) async {
    final updatedUser = user.copyWith(
      updatedAt: DateTime.now(),
    );
    
    await _users.doc(user.id).set(
      updatedUser.toMap(),
      SetOptions(merge: true),
    );
    
    return updatedUser;
  }

  @override
  Future<void> deleteUser(String userId) async {
    await _users.doc(userId).delete();
  }

  @override
  Future<void> toggleUserStatus(String userId, bool isActive) async {
    await _users.doc(userId).update({
      'isActive': isActive,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<User> ensureDefaultAdminExists({
    required String adminId,
    required String adminEmail,
    String? adminPasswordHash,
  }) async {
    // Check if admin already exists
    final existingAdmin = await getUserById(adminId);
    if (existingAdmin != null) {
      return existingAdmin;
    }
    
    // Create default admin user
    final adminUser = User(
      id: adminId,
      username: 'admin',
      email: adminEmail,
      firstName: 'Admin',
      lastName: 'System',
      isActive: true,
      isAdmin: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    return await createUser(adminUser);
  }

  /// Get users for a specific enterprise (via enterprise_module_users)
  /// This requires joining with enterprise_module_users collection
  Future<List<User>> getUsersForEnterprise(String enterpriseId) async {
    // Get enterprise module users
    final enterpriseModuleUsers = await _firestore
        .collection('enterprise_module_users')
        .where('enterpriseId', isEqualTo: enterpriseId)
        .get();
    
    // Extract unique user IDs
    final userIds = enterpriseModuleUsers.docs
        .map((doc) => doc.data()['userId'] as String)
        .toSet()
        .toList();
    
    if (userIds.isEmpty) return [];
    
    // Firestore 'in' query supports max 30 items
    // If more, we need to batch
    final users = <User>[];
    for (var i = 0; i < userIds.length; i += 30) {
      final batch = userIds.skip(i).take(30).toList();
      final snapshot = await _users
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      
      users.addAll(
        snapshot.docs.map((doc) => User.fromMap(doc.data())),
      );
    }
    
    return users;
  }

  /// Search users with filters (tenant-aware)
  Future<List<User>> searchUsersWithFilters({
    String? query,
    String? enterpriseId,
    bool? isActive,
    int? limit,
  }) async {
    Query<Map<String, dynamic>> queryRef = _users;
    
    // Apply filters
    if (isActive != null) {
      queryRef = queryRef.where('isActive', isEqualTo: isActive);
    }
    
    if (limit != null) {
      queryRef = queryRef.limit(limit);
    }
    
    final snapshot = await queryRef.get();
    var users = snapshot.docs
        .map((doc) => User.fromMap(doc.data()))
        .toList();
    
    // Filter by enterprise if specified
    if (enterpriseId != null) {
      final enterpriseUsers = await getUsersForEnterprise(enterpriseId);
      final enterpriseUserIds = enterpriseUsers.map((u) => u.id).toSet();
      users = users.where((u) => enterpriseUserIds.contains(u.id)).toList();
    }
    
    // Filter by query if specified
    if (query != null && query.trim().isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      users = users.where((user) {
        final fullName = '${user.firstName} ${user.lastName}'.toLowerCase();
        final username = user.username.toLowerCase();
        final email = user.email?.toLowerCase() ?? '';
        
        return fullName.contains(lowerQuery) ||
            username.contains(lowerQuery) ||
            email.contains(lowerQuery);
      }).toList();
    }
    
    return users;
  }
}
