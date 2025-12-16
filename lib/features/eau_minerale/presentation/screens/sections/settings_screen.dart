import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/permissions/eau_minerale_permissions.dart';
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
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  isWide ? 24 : 16,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.settings,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Paramètres',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: EauMineralePermissionGuard(
                  permission: EauMineralePermissions.manageProducts,
                  child: const PackPriceConfigCard(),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: EauMineralePermissionGuard(
                  permission: EauMineralePermissions.manageProducts,
                  child: const MachineManagementCard(),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: EauMineralePermissionGuard(
                  permission: EauMineralePermissions.configureProduction,
                  child: const ElectricityMeterConfigCard(),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: EauMineralePermissionGuard(
                  permission: EauMineralePermissions.configureProduction,
                  child: const MachineBreakdownReportCard(),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],
        );
      },
    );
  }
}
