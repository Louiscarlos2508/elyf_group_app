import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/permissions/modules/eau_minerale_permissions.dart';
import '../../widgets/centralized_permission_guard.dart';
import '../../widgets/electricity_meter_config_card.dart';
import '../../widgets/machine_breakdown_report_card.dart';
import '../../widgets/machine_management_card.dart';

/// Settings screen for the Eau Minérale module.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Titre de la page
        // Premium Header
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  const Color(0xFF00C2FF), // Cyan for Water Module
                  const Color(0xFF0369A1), // Deep Blue
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "PARAMÈTRES",
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Configuration Générale",
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Section: Production & Prix
        const SettingsSectionHeader(
          title: 'Production & Tarification',
          icon: Icons.analytics_outlined,
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverLayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.crossAxisExtent > 600;
              if (isWide) {
                return SliverGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.1, // Increased height to prevent overflow
                  children: const [
                    EauMineralePermissionGuard(
                      permission: EauMineralePermissions.configureProduction,
                      child: ElectricityMeterConfigCard(),
                    ),
                  ],
                );
              }
              return SliverList(
                delegate: SliverChildListDelegate(const [
                  EauMineralePermissionGuard(
                    permission: EauMineralePermissions.configureProduction,
                    child: ElectricityMeterConfigCard(),
                  ),
                ]),
              );
            },
          ),
        ),

        // Section: Infrastructure
        const SettingsSectionHeader(
          title: 'Infrastructure',
          icon: Icons.settings_input_component_outlined,
        ),
        const SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: EauMineralePermissionGuard(
              permission: EauMineralePermissions.manageProducts,
              child: MachineManagementCard(),
            ),
          ),
        ),

        // Section: Maintenance
        const SettingsSectionHeader(
          title: 'Maintenance & Alertes',
          icon: Icons.build_circle_outlined,
        ),
        const SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: EauMineralePermissionGuard(
              permission: EauMineralePermissions.configureProduction,
              child: MachineBreakdownReportCard(),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }
}

class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader({
    super.key,
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 12),
            Text(
              title.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
