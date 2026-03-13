import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';

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

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Titre de la page
        // Premium Header
        const ElyfModuleHeader(
          title: "Paramètres",
          subtitle: "Configuration du module Eau Minérale",
          module: EnterpriseModule.eau,
        ),

        // Section: Production & Prix
        const SettingsSectionHeader(
          title: 'Production & Tarification',
          subtitle: 'Configurez vos compteurs et tarifs énergétiques',
          icon: Icons.bolt_rounded,
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: EauMineralePermissionGuard(
              permission: EauMineralePermissions.configureProduction,
              child: const ElectricityMeterConfigCard(),
            ),
          ),
        ),

        // Section: Infrastructure
        const SettingsSectionHeader(
          title: 'Infrastructure',
          subtitle: 'Gérez votre parc de machines et équipements',
          icon: Icons.precision_manufacturing_rounded,
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
          subtitle: 'Signalez les pannes et suivez l\'état du parc',
          icon: Icons.build_circle_rounded,
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

        const SliverToBoxAdapter(child: SizedBox(height: 60)),
      ],
    );
  }
}

class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  title.toUpperCase(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            const Divider(height: 1),
          ],
        ),
      ),
    );
  }
}
