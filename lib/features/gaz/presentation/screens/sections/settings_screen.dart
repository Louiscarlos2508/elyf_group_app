import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
            (throw Exception('Aucune entreprise active disponible'));
        final effectiveModuleId = moduleId ?? 'gaz';
        final theme = Theme.of(context);
        final isMobile = MediaQuery.of(context).size.width < 800;

        return Container(
      color: const Color(0xFFF9FAFB),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(23.98),
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
                const SizedBox(height: 23.98),
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
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête avec titre et bouton
        isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configuration des prix',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: const Color(0xFF101828),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gérez les types de bouteilles et leurs tarifs',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: const Color(0xFF6A7282),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF030213),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11.99,
                        vertical: 9.99,
                      ),
                      minimumSize: const Size(136.947, 36),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const CylinderFormDialog(),
                      );
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text(
                      'Nouveau type',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Configuration des prix',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            color: const Color(0xFF101828),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Gérez les types de bouteilles et leurs tarifs',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            color: const Color(0xFF6A7282),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF030213),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11.99,
                          vertical: 9.99,
                        ),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => const CylinderFormDialog(),
                        );
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text(
                        'Nouveau type',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
        const SizedBox(height: 23.98),
        // Carte avec tableau des tarifs
        BottlePriceTable(enterpriseId: enterpriseId, moduleId: moduleId),
      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête avec titre et bouton
        isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gestion des points de vente',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: const Color(0xFF101828),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Créez et gérez les différents points de vente',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: const Color(0xFF6A7282),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF030213),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11.99,
                        vertical: 9.99,
                      ),
                      minimumSize: const Size(201.057, 36),
                    ),
                    onPressed: () async {
                      developer.log(
                        '🔵 [SETTINGS] Bouton "Nouveau point de vente" cliqué',
                        name: 'GazSettingsScreen',
                      );
                      developer.log(
                        '🔵 [SETTINGS] enterpriseId=$enterpriseId, moduleId=$moduleId',
                        name: 'GazSettingsScreen',
                      );
                      
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          developer.log(
                            '🔵 [SETTINGS] showDialog builder appelé',
                            name: 'GazSettingsScreen',
                          );
                          return PointOfSaleFormDialog(
                            enterpriseId: enterpriseId,
                            moduleId: moduleId,
                          );
                        },
                      );
                      
                      developer.log(
                        '🔵 [SETTINGS] Dialog fermé avec result=$result',
                        name: 'GazSettingsScreen',
                      );
                      
                      // Le provider sera rafraîchi dans le dialog
                      if (result == true && context.mounted) {
                        developer.log(
                          '🔵 [SETTINGS] Invalidation du provider pointsOfSaleProvider',
                          name: 'GazSettingsScreen',
                        );
                        // Forcer le rafraîchissement pour s'assurer que l'UI se met à jour
                        ref.invalidate(
                          pointsOfSaleProvider((
                            enterpriseId: enterpriseId,
                            moduleId: moduleId,
                          )),
                        );
                      }
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text(
                      'Nouveau point de vente',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gestion des points de vente',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            color: const Color(0xFF101828),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Créez et gérez les différents points de vente',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            color: const Color(0xFF6A7282),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF030213),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11.99,
                          vertical: 9.99,
                        ),
                      ),
                      onPressed: () async {
                        developer.log(
                          '🔵 [SETTINGS] Bouton "Nouveau point de vente" cliqué (desktop)',
                          name: 'GazSettingsScreen',
                        );
                        developer.log(
                          '🔵 [SETTINGS] enterpriseId=$enterpriseId, moduleId=$moduleId',
                          name: 'GazSettingsScreen',
                        );
                        
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (context) {
                            developer.log(
                              '🔵 [SETTINGS] showDialog builder appelé (desktop)',
                              name: 'GazSettingsScreen',
                            );
                            return PointOfSaleFormDialog(
                              enterpriseId: enterpriseId,
                              moduleId: moduleId,
                            );
                          },
                        );
                        
                        developer.log(
                          '🔵 [SETTINGS] Dialog fermé avec result=$result (desktop)',
                          name: 'GazSettingsScreen',
                        );
                        
                        // Le provider sera rafraîchi dans le dialog
                        if (result == true && context.mounted) {
                          developer.log(
                            '🔵 [SETTINGS] Invalidation du provider pointsOfSaleProvider (desktop)',
                            name: 'GazSettingsScreen',
                          );
                          // Forcer le rafraîchissement pour s'assurer que l'UI se met à jour
                          ref.invalidate(
                            pointsOfSaleProvider((
                              enterpriseId: enterpriseId,
                              moduleId: moduleId,
                            )),
                          );
                        }
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text(
                        'Nouveau point de vente',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
        const SizedBox(height: 23.98),
        // Carte avec tableau des points de vente
        PointOfSaleTable(enterpriseId: enterpriseId, moduleId: moduleId),
      ],
    );
  }
}
