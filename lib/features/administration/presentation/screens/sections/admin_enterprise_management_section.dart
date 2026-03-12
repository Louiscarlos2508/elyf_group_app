import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/enterprise.dart';
import '../../../application/providers.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/core/auth/services/firestore_permission_service.dart';
import 'strategies/dashboard_strategy.dart';
import 'package:elyf_groupe_app/core/permissions/data/predefined_roles.dart';

import 'package:elyf_groupe_app/core/offline/sync/sync_orchestrator.dart';

class AdminEnterpriseManagementSection extends ConsumerStatefulWidget {
  const AdminEnterpriseManagementSection({
    super.key,
    required this.enterpriseId,
  });

  final String enterpriseId;

  @override
  ConsumerState<AdminEnterpriseManagementSection> createState() => _AdminEnterpriseManagementSectionState();
}

class _AdminEnterpriseManagementSectionState extends ConsumerState<AdminEnterpriseManagementSection> {
  @override
  void initState() {
    super.initState();
    // Trigger on-demand sync for module data when viewing as admin monitoring
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerSync();
    });
  }

  Future<void> _triggerSync() async {
    final enterprise = ref.read(enterpriseByIdProvider(widget.enterpriseId)).value;
    if (enterprise != null) {
      final moduleId = enterprise.type.module.id;
      try {
        await ref.read(syncOrchestratorProvider).ensureModuleSync(moduleId, enterpriseId: widget.enterpriseId);
      } catch (e) {
        // Log error but don't block UI
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enterpriseAsync = ref.watch(enterpriseByIdProvider(widget.enterpriseId));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: enterpriseAsync.when(
          data: (enterprise) {
            if (enterprise == null) {
              return const Center(child: Text('Entreprise introuvable'));
            }
            return _buildDashboard(context, enterprise);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Erreur: $e')),
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, Enterprise enterprise) {
    final module = enterprise.type.module;
    final strategy = EnterpriseDashboardStrategy.fromEnterprise(enterprise);
    
    final personaRoles = PredefinedRoles.getRolesForEnterpriseType(enterprise.type);
    final Set<String> personaPermissions = personaRoles.isNotEmpty 
        ? personaRoles.first.permissions 
        : {'*'};

    final tabs = strategy.getTabs(personaPermissions);

    return DefaultTabController(
      length: tabs.length,
      child: Column(
        children: [
          _buildHeader(context, enterprise),
          _buildTabBar(context, module.color, tabs),
          Expanded(
            child: TabBarView(
              children: List.generate(
                tabs.length,
                (index) => ProviderScope(
                  overrides: [
                    activeEnterpriseIdProvider.overrideWith(
                      () => _ActiveEnterpriseOverrideNotifier(widget.enterpriseId),
                    ),
                    activeEnterpriseProvider.overrideWith((ref) async => enterprise),
                    unifiedPermissionServiceProvider.overrideWith((ref) {
                      final adminRepository = ref.watch(adminRepositoryProvider);
                      return _AdminMonitoringPermissionService(
                        adminRepository: adminRepository,
                        getActiveEnterpriseId: () => widget.enterpriseId,
                      );
                    }),
                  ],
                  child: Consumer(
                    builder: (context, scopedRef, _) {
                      return strategy.buildTabContent(
                        context, 
                        scopedRef, // Use scopedRef to ensure overrides are respected
                        index, 
                        enterprise, 
                        personaPermissions,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Enterprise enterprise) {
    final theme = Theme.of(context);
    final module = enterprise.type.module;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            module.color,
            module.color.withValues(alpha: 0.8),
            theme.colorScheme.secondary.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: module.color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                module.icon,
                size: 120,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              enterprise.name,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              enterprise.type.label,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: enterprise.isActive 
                              ? Colors.green.withValues(alpha: 0.8) 
                              : theme.colorScheme.outline.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          enterprise.isActive ? 'Active' : 'Inactive',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, Color color, List<Tab> tabs) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        isScrollable: tabs.length > 3,
        indicator: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
        ),
        labelColor: color,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: tabs,
      ),
    );
  }

}

class _ActiveEnterpriseOverrideNotifier extends ActiveEnterpriseIdNotifier {
  _ActiveEnterpriseOverrideNotifier(this.overriddenId);
  final String overriddenId;

  @override
  Future<String?> build() async => overriddenId;

  @override
  Future<void> setActiveEnterpriseId(String enterpriseId) async {
    // No-op for admin monitor mode
  }
}

/// A permission service that allows everything for admin monitoring mode.
class _AdminMonitoringPermissionService extends FirestorePermissionService {
  _AdminMonitoringPermissionService({
    required super.adminRepository,
    required super.getActiveEnterpriseId,
  });

  @override
  Future<bool> hasPermission(
    String userId,
    String moduleId,
    String permissionId, {
    String? enterpriseId,
  }) async => true;

  @override
  Future<bool> hasEnterpriseAccess(String userId, String enterpriseId) async => true;

  @override
  Future<bool> hasModuleAccess(String userId, String enterpriseId, String moduleId) async => true;

  @override
  Future<Set<String>> getUserPermissions(String userId, String moduleId, {String? enterpriseId}) async {
    return {'*'};
  }
}
