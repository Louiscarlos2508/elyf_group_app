import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/core/offline/base_providers.dart';
import 'package:elyf_groupe_app/core/auth/providers.dart';
import 'package:elyf_groupe_app/core/firebase/providers.dart' as fb_providers;
import 'package:elyf_groupe_app/core/tenant/services/tenant_context_service.dart';
export 'package:elyf_groupe_app/core/tenant/services/tenant_context_service.dart';

// Domain Interfaces
import 'package:elyf_groupe_app/features/administration/domain/repositories/admin_repository.dart';
import 'package:elyf_groupe_app/features/administration/domain/repositories/enterprise_repository.dart';
import 'package:elyf_groupe_app/features/administration/domain/repositories/user_repository.dart';

// Data Implementations
import 'package:elyf_groupe_app/features/administration/data/repositories/admin_offline_repository.dart';
import 'package:elyf_groupe_app/features/administration/data/repositories/admin_firestore_repository.dart';
import 'package:elyf_groupe_app/features/administration/data/repositories/user_offline_repository.dart';
import 'package:elyf_groupe_app/features/administration/data/repositories/user_firestore_repository.dart';
import 'package:elyf_groupe_app/features/administration/data/repositories/enterprise_offline_repository.dart';
import 'package:elyf_groupe_app/features/administration/data/repositories/enterprise_firestore_repository.dart';

/// Providers for repositories to avoid circular dependencies with Tenant/Auth.
/// Bases for platform-aware repository selection.

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  if (kIsWeb) {
    return AdminFirestoreRepository(
      firestore: ref.watch(fb_providers.firestoreProvider),
    );
  } else {
    return AdminOfflineRepository(
      driftService: ref.watch(driftServiceProvider),
      syncManager: ref.watch(syncManagerProvider),
      connectivityService: ref.watch(connectivityServiceProvider),
      userRepository: ref.watch(userRepositoryProvider),
    );
  }
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  if (kIsWeb) {
    return UserFirestoreRepository(
      firestore: ref.watch(fb_providers.firestoreProvider),
    );
  } else {
    return UserOfflineRepository(
      driftService: ref.watch(driftServiceProvider),
      syncManager: ref.watch(syncManagerProvider),
      connectivityService: ref.watch(connectivityServiceProvider),
    );
  }
});

final enterpriseRepositoryProvider = Provider<EnterpriseRepository>((ref) {
  if (kIsWeb) {
    return EnterpriseFirestoreRepository(
      firestore: ref.watch(fb_providers.firestoreProvider),
      authService: ref.watch(authServiceProvider),
    );
  } else {
    return EnterpriseOfflineRepository(
      driftService: ref.watch(driftServiceProvider),
      syncManager: ref.watch(syncManagerProvider),
      connectivityService: ref.watch(connectivityServiceProvider),
    );
  }
});

/// Provider for TenantContextService
final tenantContextServiceProvider = Provider<TenantContextService>((ref) {
  return TenantContextService(
    ref.watch(enterpriseRepositoryProvider),
    ref.watch(adminRepositoryProvider),
  );
});
