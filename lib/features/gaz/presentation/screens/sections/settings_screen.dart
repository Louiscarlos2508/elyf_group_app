import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/core/logging/app_logger.dart';


import '../../../../../../core/tenant/tenant_provider.dart' show activeEnterpriseProvider;
import 'package:elyf_groupe_app/features/administration/application/providers.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import '../../widgets/bottle_price_table.dart';
import '../../widgets/cylinder_form_dialog.dart';
import '../../widgets/point_of_sale_form_dialog.dart';
import '../../widgets/point_of_sale_table.dart';
import '../../widgets/gaz_header.dart';
import '../../../application/providers.dart';

/// Écran de paramètres pour le module Gaz selon le design Figma.
class GazSettingsScreen extends ConsumerWidget {
  const GazSettingsScreen({super.key, this.enterpriseId, this.moduleId});

  final String? enterpriseId;
  final String? moduleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Récupérer l'entreprise active
    final activeEnterpriseAsync = ref.watch(activeEnterpriseProvider);
    
    return activeEnterpriseAsync.when(
      data: (enterprise) {
        if (enterprise == null && enterpriseId == null) {
          return const Scaffold(
            body: Center(
              child: Text('Veuillez sélectionner une entreprise pour accéder aux paramètres.'),
            ),
          );
        }

        final effectiveEnterpriseId = enterpriseId ?? enterprise?.id ?? '';
        final effectiveModuleId = moduleId ?? 'gaz';

        // 2. Vérifier les permissions via le provider stable
        final hasAccessAsync = ref.watch(userHasGazPermissionProvider('manage_cylinders'));

        return hasAccessAsync.when(
          data: (hasAccess) {
            if (!hasAccess) {
              return const Scaffold(
                body: Center(
                  child: Text('Accès refusé. Vous devez être administrateur.'),
                ),
              );
            }

            final theme = Theme.of(context);
            final isMobile = MediaQuery.of(context).size.width < 800;

            return Scaffold(
              backgroundColor: theme.colorScheme.surface,
              body: CustomScrollView(
                slivers: [
                  const GazHeader(
                    title: 'ADMINISTRATION',
                    subtitle: 'Paramètres Gaz',
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child: _buildPriceConfigurationSection(
                        context: context,
                        theme: theme,
                        enterpriseId: effectiveEnterpriseId,
                        moduleId: effectiveModuleId,
                        isMobile: isMobile,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child: _buildPointOfSaleSection(
                        context: context,
                        ref: ref,
                        theme: theme,
                        enterpriseId: effectiveEnterpriseId,
                        moduleId: effectiveModuleId,
                        isMobile: isMobile,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child: _buildStockAlertSection(
                        context: context,
                        ref: ref,
                        theme: theme,
                        enterpriseId: effectiveEnterpriseId,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child: _buildDefaultFeesSection(
                        context: context,
                        ref: ref,
                        theme: theme,
                        enterpriseId: effectiveEnterpriseId,
                      ),
                    ),
                  ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 60)),
                ],
              ),
            );
          },
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, _) => Scaffold(body: Center(child: Text('Erreur permission: $error'))),
        );
      },
      loading: () => Scaffold(body: AppShimmers.list(context)),
      error: (error, _) => Scaffold(
        body: Center(child: Text('Erreur chargement entreprise: $error')),
      ),
    );
  }

  /// Construit la section de configuration des prix.
  Widget _buildPriceConfigurationSection({
    required BuildContext context,
    required ThemeData theme,
    required String enterpriseId,
    required String moduleId,
    required bool isMobile,
  }) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.monetization_on_outlined,
                    size: 20, // Slightly smaller icon on mobile
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configuration des prix',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!isMobile) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Gérez les bouteilles et tarifs',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                isMobile ? ElyfButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => CylinderFormDialog(
                        enterpriseId: enterpriseId,
                        moduleId: moduleId,
                      ),
                    );
                  },
                  size: ElyfButtonSize.small,
                  icon: Icons.add,
                  child: const Text('Nouveau'),
                )
                    : ElyfButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => CylinderFormDialog(
                              enterpriseId: enterpriseId,
                              moduleId: moduleId,
                            ),
                          );
                        },
                        icon: Icons.add,
                        child: const Text('Nouveau type'),
                      ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            // Carte avec tableau des tarifs
            BottlePriceTable(enterpriseId: enterpriseId, moduleId: moduleId),
          ],
        ),
      ),
    );
  }

  /// Construit la section de gestion des points de vente.
  Widget _buildPointOfSaleSection({
    required BuildContext context,
    required WidgetRef ref,
    required ThemeData theme,
    required String enterpriseId,
    required String moduleId,
    required bool isMobile,
  }) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.storefront_outlined,
                    size: 20, // Slightly smaller on mobile
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gestion des points de vente',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!isMobile) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Gérez points de vente et stocks',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                isMobile ? ElyfButton(
                  onPressed: () async {
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return PointOfSaleFormDialog(
                          enterpriseId: enterpriseId,
                          moduleId: moduleId,
                        );
                      },
                    );

                    if (result == true && context.mounted) {
                      ref.invalidate(
                        enterprisesByParentAndTypeProvider((
                          parentId: enterpriseId,
                          type: EnterpriseType.gasPointOfSale,
                        )),
                      );
                    }
                  },
                  size: ElyfButtonSize.small,
                  icon: Icons.add,
                  child: const Text('Nouveau'),
                )
                    : ElyfButton(
                        onPressed: () async {
                          AppLogger.debug(
                            '[SETTINGS] Bouton "Nouveau point de vente" cliqué',
                            name: 'GazSettingsScreen',
                          );

                          final result = await showDialog<bool>(
                            context: context,
                            builder: (context) {
                              return PointOfSaleFormDialog(
                                enterpriseId: enterpriseId,
                                moduleId: moduleId,
                              );
                            },
                          );

                          if (result == true && context.mounted) {
                            ref.invalidate(
                                enterprisesByParentAndTypeProvider((
                                  parentId: enterpriseId,
                                  type: EnterpriseType.gasPointOfSale,
                                )),
                            );
                          }
                        },
                        icon: Icons.add,
                        child: const Text('Nouveau point de vente'),
                      ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            // Carte avec tableau des points de vente
            PointOfSaleTable(enterpriseId: enterpriseId, moduleId: moduleId),
          ],
        ),
      ),
    );
  }

  Widget _buildStockAlertSection({
    required BuildContext context,
    required WidgetRef ref,
    required ThemeData theme,
    required String enterpriseId,
  }) {
    final settingsAsync = ref.watch(gazSettingsProvider((enterpriseId: enterpriseId, moduleId: 'gaz')));

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.notifications_active_outlined,
                    size: 20,
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alertes de stock bas',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Définissez les seuils d\'alerte par poids',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            settingsAsync.when(
              data: (settings) {
                // Use settings price keys rather than cylinder objects — works on new devices too
                final weights = {
                  ...?settings?.retailPrices.keys,
                  ...?settings?.purchasePrices.keys,
                  ...?settings?.wholesalePrices.keys,
                }.toList()..sort();
                if (weights.isEmpty) {
                  return const Center(child: Text('Aucun type de bouteille configuré'));
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: weights.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final weight = weights[index];
                    final threshold = settings?.getLowStockThreshold(weight) ?? 0;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('$weight kg'),
                      subtitle: Text('Seuil actuel : $threshold bouteilles'),
                      trailing: SizedBox(
                        width: 100,
                        child: ElyfButton(
                          onPressed: () => _showThresholdEditDialog(
                            context,
                            ref,
                            enterpriseId,
                            weight,
                            threshold,
                          ),
                          size: ElyfButtonSize.small,
                          child: const Text('Modifier'),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Erreur paramètres: $e'),
            ),
          ],
        ),
      ),
    );
  }

  void _showThresholdEditDialog(
    BuildContext context,
    WidgetRef ref,
    String enterpriseId,
    int weight,
    int currentThreshold,
  ) {
    final controller = TextEditingController(text: currentThreshold.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Seuil d\'alerte ($weight kg)'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Seuil (nombre de bouteilles)',
            helperText: 'L\'alerte se déclenche sous ce nombre',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newThreshold = int.tryParse(controller.text) ?? 0;
              await ref.read(gazSettingsControllerProvider).setLowStockThreshold(
                enterpriseId: enterpriseId,
                moduleId: 'gaz',
                weight: weight,
                threshold: newThreshold,
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }


  /// Construit la section des frais logistiques par défaut.
  Widget _buildDefaultFeesSection({
    required BuildContext context,
    required WidgetRef ref,
    required ThemeData theme,
    required String enterpriseId,
  }) {
    final settingsAsync = ref.watch(gazSettingsProvider((enterpriseId: enterpriseId, moduleId: 'gaz')));

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.local_shipping_outlined,
                    size: 20,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Frais Logistiques par Défaut',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Frais appliqués automatiquement lors des tours',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            settingsAsync.when(
              data: (settings) {
                // Use settings price keys rather than cylinder objects — works on new devices too
                final weights = {
                  ...?settings?.retailPrices.keys,
                  ...?settings?.purchasePrices.keys,
                  ...?settings?.loadingFees.keys,
                  ...?settings?.unloadingFees.keys,
                }.toList()..sort();
                if (weights.isEmpty) {
                  return const Center(child: Text('Aucun type de bouteille configuré'));
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: weights.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final weight = weights[index];
                    final loading = settings?.loadingFees[weight] ?? 0.0;
                    final unloading = settings?.unloadingFees[weight] ?? 0.0;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('$weight kg'),
                      subtitle: Text('Chargement: ${loading.toInt()} F | Déchargement: ${unloading.toInt()} F'),
                      trailing: SizedBox(
                        width: 100,
                        child: ElyfButton(
                          onPressed: () => _showFeesEditDialog(
                            context,
                            ref,
                            enterpriseId,
                            weight,
                            loading,
                            unloading,
                          ),
                          size: ElyfButtonSize.small,
                          child: const Text('Modifier'),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Erreur paramètres: $e'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFeesEditDialog(
    BuildContext context,
    WidgetRef ref,
    String enterpriseId,
    int weight,
    double currentLoading,
    double currentUnloading,
  ) {
    final loadingController = TextEditingController(text: currentLoading.toInt().toString());
    final unloadingController = TextEditingController(text: currentUnloading.toInt().toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text('Frais par défaut ($weight kg)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: loadingController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Frais de chargement (Unit.)',
                suffixText: 'FCFA',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: unloadingController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Frais de déchargement (Unit.)',
                suffixText: 'FCFA',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newLoading = double.tryParse(loadingController.text) ?? 0.0;
              final newUnloading = double.tryParse(unloadingController.text) ?? 0.0;
              
              final controller = ref.read(gazSettingsControllerProvider);
              await controller.setLoadingFee(
                enterpriseId: enterpriseId,
                moduleId: 'gaz',
                weight: weight,
                fee: newLoading,
              );
              await controller.setUnloadingFee(
                enterpriseId: enterpriseId,
                moduleId: 'gaz',
                weight: weight,
                fee: newUnloading,
              );
              
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
