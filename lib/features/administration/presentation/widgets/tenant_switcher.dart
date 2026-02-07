import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/tenant_providers.dart';
import '../../domain/entities/enterprise.dart';

/// Dropdown pour changer de tenant
/// Affiche tous les tenants accessibles par l'utilisateur
class TenantSwitcher extends ConsumerWidget {
  const TenantSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentTenantAsync = ref.watch(currentTenantProvider);
    final accessibleTenantsAsync = ref.watch(accessibleTenantsProvider);

    return accessibleTenantsAsync.when(
      data: (tenants) {
        if (tenants.isEmpty) {
          return const SizedBox.shrink();
        }

        return currentTenantAsync.when(
          data: (currentTenant) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: currentTenant?.id,
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: theme.colorScheme.onSurface,
                  ),
                  isDense: true,
                  items: tenants.map((tenant) {
                    return DropdownMenuItem<String>(
                      value: tenant.id,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _getIcon(tenant.type, theme),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              tenant.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (tenant.hierarchyLevel > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(Niv. ${tenant.hierarchyLevel})',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (tenantId) {
                    if (tenantId != null) {
                      ref.read(currentTenantIdProvider.notifier).setTenantId(tenantId);
                    }
                  },
                ),
              ),
            );
          },
          loading: () => const SizedBox(
            width: 200,
            height: 40,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox(
        width: 200,
        height: 40,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _getIcon(EnterpriseType type, ThemeData theme) {
    IconData iconData;
    Color? color;

    switch (type) {
      case EnterpriseType.group:
        iconData = Icons.corporate_fare;
        color = theme.colorScheme.primary;
        break;
      case EnterpriseType.gasCompany:
      case EnterpriseType.waterEntity:
        iconData = Icons.business;
        color = theme.colorScheme.primary;
        break;
      case EnterpriseType.gasPointOfSale:
      case EnterpriseType.waterPointOfSale:
        iconData = Icons.store;
        color = theme.colorScheme.secondary;
        break;
      case EnterpriseType.gasWarehouse:
      case EnterpriseType.waterWarehouse:
        iconData = Icons.warehouse;
        color = theme.colorScheme.tertiary;
        break;
      case EnterpriseType.waterFactory:
        iconData = Icons.factory;
        color = theme.colorScheme.tertiary;
        break;
      case EnterpriseType.realEstateAgency:
      case EnterpriseType.realEstateBranch:
        iconData = Icons.home_work;
        color = theme.colorScheme.secondary;
        break;
      case EnterpriseType.shop:
      case EnterpriseType.shopBranch:
        iconData = Icons.shopping_bag;
        color = theme.colorScheme.secondary;
        break;
      case EnterpriseType.mobileMoneyAgent:
      case EnterpriseType.mobileMoneySubAgent:
        iconData = Icons.account_balance_wallet;
        color = Colors.orange;
        break;
      case EnterpriseType.mobileMoneyDistributor:
      case EnterpriseType.mobileMoneyKiosk:
        iconData = Icons.point_of_sale;
        color = Colors.orange.shade700;
        break;
    }

    return Icon(iconData, size: 18, color: color);
  }
}
