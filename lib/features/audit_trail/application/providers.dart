import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/offline/drift_service.dart';
import '../../../../core/offline/providers.dart';
import '../data/repositories/audit_trail_offline_repository.dart';
import '../domain/repositories/audit_trail_repository.dart';
import '../domain/services/audit_trail_service.dart';

/// Provider for AuditTrailRepository.
final auditTrailRepositoryProvider = Provider<AuditTrailRepository>((ref) {
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);

  return AuditTrailOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
  );
});

/// Provider for AuditTrailService.
final auditTrailServiceProvider = Provider<AuditTrailService>((ref) {
  return AuditTrailService(ref.watch(auditTrailRepositoryProvider));
});
