import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/errors/app_exceptions.dart';

import '../../../../../../core/tenant/tenant_provider.dart' show activeEnterpriseProvider;
import '../../widgets/bottle_price_table.dart';
import '../../widgets/cylinder_form_dialog.dart';
import '../../widgets/point_of_sale_form_dialog.dart';
import '../../widgets/point_of_sale_table.dart';
import '../../../application/providers.dart' show pointsOfSaleProvider;

/// Écran de paramètres pour le module Gaz selon le design Figma.
class GazSettingsScreen extends ConsumerWidget {
  const GazSettingsScreen({super.key, this.enterpriseId, this.moduleId});

  final String? enterpriseId;
  final String? moduleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Récupérer l'entreprise active depuis le tenant provider
    final activeEnterpriseAsync = ref.watch(activeEnterpriseProvider);
    
    return activeEnterpriseAsync.when(
      data: (enterprise) {
        final effectiveEnterpriseId = enterpriseId ?? 
            enterprise?.id ?? 
            (throw NotFoundException(
              'Aucune entreprise active disponible',
              'NO_ACTIVE_ENTERPRISE',
            ));
        final effectiveModuleId = moduleId ?? 'gaz';
        
        // Debug: Log l'entreprise active
        developer.log(
          '🔵 GazSettingsScreen: enterprise=${enterprise?.name} (${enterprise?.id}), type=${enterprise?.type}, effectiveEnterpriseId=$effectiveEnterpriseId',
          name: 'GazSettingsScreen',
        );
        final theme = Theme.of(context);
        final isMobile = MediaQuery.of(context).size.width < 800;

        return Container(
          color: const Color(0xFFF9FAFB),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Section Configuration des prix
                    _buildPriceConfigurationSection(
                      context: context,
                      theme: theme,
                      enterpriseId: effectiveEnterpriseId,
                      moduleId: effectiveModuleId,
                      isMobile: isMobile,
                    ),
                    const SizedBox(height: 24),
                    // Section Gestion des points de vente
                    _buildPointOfSaleSection(
                      context: context,
                      ref: ref,
                      theme: theme,
                      enterpriseId: effectiveEnterpriseId,
                      moduleId: effectiveModuleId,
                      isMobile: isMobile,
                    ),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        body: AppShimmers.list(context),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Paramètres')),
        body: Center(
          child: Text('Erreur: $error'),
        ),
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
      color: Colors.white,
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
                    color: const Color(0xFFF2F4F7),
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
                isMobile
                    ? IconButton.filled(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => const CylinderFormDialog(),
                          );
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF030213),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.add, size: 20),
                      )
                    : FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF030213),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => const CylinderFormDialog(),
                          );
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Nouveau type'),
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
      color: Colors.white,
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
                    color: const Color(0xFFF2F4F7),
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
                isMobile
                    ? IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF030213),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
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
                              pointsOfSaleProvider((
                                enterpriseId: enterpriseId,
                                moduleId: moduleId,
                              )),
                            );
                          }
                        },
                        icon: const Icon(Icons.add, size: 20),
                      )
                    : FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF030213),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () async {
                          developer.log(
                            '🔵 [SETTINGS] Bouton "Nouveau point de vente" cliqué',
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
                              pointsOfSaleProvider((
                                enterpriseId: enterpriseId,
                                moduleId: moduleId,
                              )),
                            );
                          }
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Nouveau point de vente'),
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
}
