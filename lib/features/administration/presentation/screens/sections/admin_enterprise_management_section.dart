import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/enterprise.dart';
import '../../../application/providers.dart';
import 'strategies/dashboard_strategy.dart';

class AdminEnterpriseManagementSection extends ConsumerWidget {
  const AdminEnterpriseManagementSection({
    super.key,
    required this.enterpriseId,
  });

  final String enterpriseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Utilisation directe de l'ID passé en paramètre
    final enterpriseAsync = ref.watch(enterpriseByIdProvider(enterpriseId));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: enterpriseAsync.when(
          data: (enterprise) {
            if (enterprise == null) {
              return const Center(child: Text('Entreprise introuvable'));
            }
            return _buildDashboard(context, ref, enterprise);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Erreur: $e')),
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, WidgetRef ref, Enterprise enterprise) {
    final module = enterprise.type.module;
    final strategy = EnterpriseDashboardStrategy.fromEnterprise(enterprise);
    final tabs = strategy.getTabs();

    return DefaultTabController(
      length: tabs.length,
      child: Column(
        children: [
          // Header avec bouton retour et infos entreprise
          _buildHeader(context, enterprise),

          // TabBar
          _buildTabBar(context, module.color, tabs),

          // Content
          Expanded(
            child: TabBarView(
              children: List.generate(
                tabs.length,
                (index) => strategy.buildTabContent(context, ref, index, enterprise),
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
                          color: enterprise.isActive ? Colors.green : Colors.grey,
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
        isScrollable: tabs.length > 3, // Scrollable if many tabs
        indicator: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
        ),
        labelColor: color,
        unselectedLabelColor: Colors.grey,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: tabs,
      ),
    );
  }

}
