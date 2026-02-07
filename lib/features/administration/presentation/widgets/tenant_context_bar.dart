import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/tenant_providers.dart';
import '../../domain/entities/enterprise.dart';

/// Barre de contexte tenant affichant la hiérarchie actuelle
/// À placer en haut de tous les écrans admin pour montrer où l'utilisateur se trouve
class TenantContextBar extends ConsumerWidget {
  const TenantContextBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final breadcrumbsAsync = ref.watch(tenantBreadcrumbsProvider);

    return breadcrumbsAsync.when(
      data: (breadcrumbs) {
        if (breadcrumbs.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.business,
                size: 20,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (int i = 0; i < breadcrumbs.length; i++) ...[
                      if (i > 0)
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: theme.colorScheme.onPrimaryContainer
                              .withValues(alpha: 0.6),
                        ),
                      _BreadcrumbItem(
                        enterprise: breadcrumbs[i],
                        isLast: i == breadcrumbs.length - 1,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        height: 48,
        color: theme.colorScheme.surfaceContainerHighest,
        child: const Center(
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
}

/// Item individuel du breadcrumb
class _BreadcrumbItem extends ConsumerWidget {
  const _BreadcrumbItem({
    required this.enterprise,
    required this.isLast,
  });

  final Enterprise enterprise;
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onPrimaryContainer,
      fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
    );

    if (isLast) {
      // Dernier élément : pas cliquable
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _getIcon(enterprise.type, theme),
          const SizedBox(width: 6),
          Text(enterprise.name, style: textStyle),
        ],
      );
    }

    // Éléments précédents : cliquables pour navigation
    return InkWell(
      onTap: () {
        ref.read(currentTenantIdProvider.notifier).setTenantId(enterprise.id);
      },
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _getIcon(enterprise.type, theme),
            const SizedBox(width: 6),
            Text(enterprise.name, style: textStyle),
          ],
        ),
      ),
    );
  }

  Widget _getIcon(EnterpriseType type, ThemeData theme) {
    IconData iconData = Icons.business;

    switch (type) {
      case EnterpriseType.group:
        iconData = Icons.corporate_fare;
        break;
      case EnterpriseType.gasCompany:
      case EnterpriseType.waterEntity:
        iconData = Icons.business;
        break;
      case EnterpriseType.gasPointOfSale:
      case EnterpriseType.waterPointOfSale:
        iconData = Icons.store;
        break;
      case EnterpriseType.gasWarehouse:
      case EnterpriseType.waterWarehouse:
        iconData = Icons.warehouse;
        break;
      case EnterpriseType.waterFactory:
        iconData = Icons.factory;
        break;
      case EnterpriseType.realEstateAgency:
      case EnterpriseType.realEstateBranch:
        iconData = Icons.home_work;
        break;
      case EnterpriseType.shop:
      case EnterpriseType.shopBranch:
        iconData = Icons.shopping_bag;
        break;
      case EnterpriseType.mobileMoneyAgent:
      case EnterpriseType.mobileMoneySubAgent:
        iconData = Icons.account_balance_wallet;
        break;
      case EnterpriseType.mobileMoneyDistributor:
      case EnterpriseType.mobileMoneyKiosk:
        iconData = Icons.point_of_sale;
        break;
    }

    return Icon(
      iconData,
      size: 16,
      color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
    );
  }
}
