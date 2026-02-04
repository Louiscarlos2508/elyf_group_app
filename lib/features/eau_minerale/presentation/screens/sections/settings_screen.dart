import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/permissions/modules/eau_minerale_permissions.dart';
import '../../widgets/centralized_permission_guard.dart';
import '../../widgets/electricity_meter_config_card.dart';
import '../../widgets/machine_breakdown_report_card.dart';
import '../../widgets/machine_management_card.dart';
import '../../widgets/pack_price_config_card.dart';

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
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Text(
              'Paramètres',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
                  childAspectRatio: 1.5,
                  children: const [
                    EauMineralePermissionGuard(
                      permission: EauMineralePermissions.manageProducts,
                      child: PackPriceConfigCard(),
                    ),
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
                    permission: EauMineralePermissions.manageProducts,
                    child: PackPriceConfigCard(),
                  ),
                  SizedBox(height: 16),
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
