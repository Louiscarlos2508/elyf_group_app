import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/gaz/application/providers.dart' hide currentUserIdProvider;
import 'package:elyf_groupe_app/core/auth/providers.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/tour.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/cylinder.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/cylinder_stock.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/cylinder_leak.dart';
import 'package:elyf_groupe_app/features/gaz/domain/services/gaz_stock_calculation_service.dart';
import 'package:elyf_groupe_app/features/gaz/presentation/widgets/wholesale/independent_collection_dialog.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/collection.dart';

/// Contenu de l'étape Chargement du tour.
///
/// Permet de saisir les quantités de bouteilles vides à charger
/// pour les échanger chez le fournisseur.
class LoadingStepContent extends ConsumerStatefulWidget {
  const LoadingStepContent({
    super.key,
    required this.tour,
    required this.enterpriseId,
    this.onSaved,
  });

  final Tour tour;
  final String enterpriseId;
  final VoidCallback? onSaved;

  @override
  ConsumerState<LoadingStepContent> createState() => _LoadingStepContentState();
}

class _LoadingStepContentState extends ConsumerState<LoadingStepContent> {
  final Map<int, TextEditingController> _emptyControllers = {};
  final Map<int, TextEditingController> _leakingControllers = {};
  final bool _loadingSettings = false;

  @override
  void dispose() {
    for (final controller in _emptyControllers.values) {
      controller.dispose();
    }
    for (final controller in _leakingControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cylindersAsync = ref.watch(cylindersProvider);
    final emptyStocksAsync = ref.watch(gazStocksProvider);
    final reportedLeaksAsync = ref.watch(cylinderLeaksProvider((
      enterpriseId: widget.enterpriseId,
      status: LeakStatus.reported,
    )));

    final activeEnterprise = ref.watch(activeEnterpriseProvider).value;
    final isPos = activeEnterprise?.id == widget.enterpriseId && (activeEnterprise?.isPointOfSale ?? false);
    final collectionsAsync = ref.watch(tourCollectionsProvider(widget.tour.id));

    return cylindersAsync.when(
      data: (cylinders) {
        final weights = cylinders.map((c) => c.weight).toSet().toList()..sort();
        final allStocks = (emptyStocksAsync.value ?? [])
            .where((s) => s.enterpriseId == widget.enterpriseId && s.siteId == null)
            .toList();
        final emptyStocks = GazStockCalculationService.filterEmptyStocks(allStocks);
        
        // Initialize controllers for weights if not already present
        bool neededSettingsLoad = false;
        for (final weight in weights) {
          if (!_emptyControllers.containsKey(weight)) {
            _emptyControllers[weight] = TextEditingController(
              text: (widget.tour.emptyBottlesLoaded[weight] ?? 0).toString(),
            );
            _leakingControllers[weight] = TextEditingController(
              text: (widget.tour.leakingBottlesLoaded[weight] ?? 0).toString(),
            );
            neededSettingsLoad = true;
          }
        }

        if (neededSettingsLoad) {
          // Additional logic if required, skipped nominal stocks
        }

        return Container(
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.surfaceContainerLow : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Chargement des bouteilles vides',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: weights.length,
                separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (context, index) {
                  final weight = weights[index];
                  final cylinderId = cylinders.any((Cylinder c) => c.weight == weight) 
                      ? cylinders.firstWhere((Cylinder c) => c.weight == weight).id 
                      : '';
                  final atStoreQty = allStocks
                      .where((s) => s.cylinderId == cylinderId && s.status == CylinderStatus.emptyAtStore)
                      .fold<int>(0, (sum, s) => sum + s.quantity);
                  final inTransitQty = allStocks
                      .where((s) => s.cylinderId == cylinderId && s.status == CylinderStatus.emptyInTransit)
                      .fold<int>(0, (sum, s) => sum + s.quantity);
                  final availableEmpty = atStoreQty + inTransitQty;

                  final leakQty = allStocks
                      .where((s) => s.cylinderId == cylinderId && s.status == CylinderStatus.leak)
                      .fold<int>(0, (sum, s) => sum + s.quantity);
                  final leakInTransitQty = allStocks
                      .where((s) => s.cylinderId == cylinderId && s.status == CylinderStatus.leakInTransit)
                      .fold<int>(0, (sum, s) => sum + s.quantity);
                  final availableLeak = leakQty + leakInTransitQty;
                  
                  final emptyController = _emptyControllers[weight];
                  final emptyTyped = int.tryParse(emptyController?.text ?? '0') ?? 0;

                  final leakingController = _leakingControllers[weight];
                  final leakingTyped = int.tryParse(leakingController?.text ?? '0') ?? 0;

                  // Calcul du max pour les fuites basé sur les signalements réels
                  final reportedLeaks = reportedLeaksAsync.value ?? [];
                  final reportedForWeight = reportedLeaks
                      .where((l) => l.weight == weight && l.cylinderId == cylinderId)
                      .length;
                  final maxLeakAvailable = reportedForWeight + (widget.tour.leakingBottlesLoaded[weight] ?? 0);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        // Left: Weight info
                        SizedBox(
                          width: 60,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$weight',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                'kg',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Right: Interactive Entry (Empty & Leaking)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Empty Row
                              _buildInputRow(
                                context: context,
                                label: 'Vides',
                                controller: emptyController,
                                typedQty: emptyTyped,
                                accentColor: theme.colorScheme.primary,
                              ),
                              const SizedBox(height: 8),
                              // Leaking Row
                              _buildInputRow(
                                context: context,
                                label: 'Fuites',
                                controller: leakingController,
                                typedQty: leakingTyped,
                                accentColor: Colors.redAccent,
                                isLeak: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              
              // Wholesaler (Grossistes) Section
              _buildWholesalerSection(context, theme, collectionsAsync),

              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: () => _saveLoading(cylinders, emptyStocks),
                  icon: const Icon(Icons.local_shipping_outlined, size: 20),
                  label: const Text('Valider le chargement'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (e, _) => Center(
        child: Text('Erreur lors du chargement des types de bouteilles: $e'),
      ),
    );
  }

  Future<void> _saveLoading(List<Cylinder> cylinders, List<CylinderStock> allStocks) async {
    final emptyBottles = <int, int>{};
    final leakingBottles = <int, int>{};
    final errors = <String>[];

    // 1. Validation Bouteilles Vides
    for (final entry in _emptyControllers.entries) {
      final weight = entry.key;
      final qty = int.tryParse(entry.value.text) ?? 0;
      final oldQty = widget.tour.emptyBottlesLoaded[weight] ?? 0;
      final delta = qty - oldQty;

      if (delta > 0) {
        final cylinderId = cylinders.firstWhere((Cylinder c) => c.weight == weight).id;
        final emptyAtStore = allStocks
            .where((s) => s.cylinderId == cylinderId && s.status == CylinderStatus.emptyAtStore)
            .fold<int>(0, (sum, s) => sum + s.quantity);

        if (delta > emptyAtStore) {
          errors.add('Vides $weight kg : +$delta demandés, mais seulement $emptyAtStore au magasin');
        }
      }
      if (qty > 0) emptyBottles[weight] = qty;
    }

    // 2. Validation Bouteilles avec Fuite
    for (final entry in _leakingControllers.entries) {
      final weight = entry.key;
      final qty = int.tryParse(entry.value.text) ?? 0;
      final oldQty = widget.tour.leakingBottlesLoaded[weight] ?? 0;
      final delta = qty - oldQty;

      if (delta > 0) {
        final cylinderId = cylinders.firstWhere((Cylinder c) => c.weight == weight).id;
        
        // 1. Check physical stock
        final leaksAtStore = allStocks
            .where((s) => s.cylinderId == cylinderId && s.status == CylinderStatus.leak)
            .fold<int>(0, (sum, s) => sum + s.quantity);

        if (delta > leaksAtStore) {
          errors.add('Fuites $weight kg : +$delta demandés, mais seulement $leaksAtStore en stock physique');
        }

      // Checking reported records can be kept if desired, but we removed it to keep UI simple
      // and match the pure declarative nature requested.
      }
      if (qty > 0) leakingBottles[weight] = qty;
    }

    if (errors.isNotEmpty) {
      if (mounted) {
        NotificationService.showError(context, 'Stock insuffisant :\n${errors.join('\n')}');
      }
      return;
    }

    if (emptyBottles.isEmpty && leakingBottles.isEmpty) {
      if (mounted) NotificationService.showError(context, 'Saisissez au moins une quantité');
      return;
    }

    try {
      final controller = ref.read(tourControllerProvider);
      final userId = ref.read(currentUserIdProvider);

      if (userId == null) {
        if (mounted) NotificationService.showError(context, 'Utilisateur non identifié');
        return;
      }

      await controller.updateEmptyBottlesLoaded(
        widget.tour.id,
        emptyBottles,
        userId,
        leakingQuantities: leakingBottles,
      );

      if (mounted) {
        NotificationService.showSuccess(context, 'Chargement enregistré');
        ref.invalidate(tourProvider(widget.tour.id));
        widget.onSaved?.call();
      }
    } catch (e) {
      if (mounted) NotificationService.showError(context, 'Erreur: $e');
    }
  }

  Widget _buildStockMini(BuildContext context, String label, int value, Color color, {bool isItalic = false}) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            fontStyle: isItalic ? FontStyle.italic : null,
          ),
        ),
        Text(
          value.toString(),
          style: theme.textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    VoidCallback? onPressed,
    Color? color,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: (color ?? Colors.grey).withValues(alpha: 0.2),
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        color: color,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: BoxConstraints.tight(const Size(32, 32)),
      ),
    );
  }

  Widget _buildInputRow({
    required BuildContext context,
    required String label,
    required TextEditingController? controller,
    required int typedQty,
    required Color accentColor,
    bool isLeak = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        // Stock labels (Removed)
        const Expanded(child: SizedBox()),
        const SizedBox(width: 16),
        // Interactions
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCircleButton(
              icon: Icons.remove,
              onPressed: typedQty > 0 ? () {
                setState(() {
                  controller?.text = (typedQty - 1).toString();
                });
              } : null,
            ),
            Container(
              width: 40,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                ),
                onChanged: (v) {
                  setState(() {});
                },
              ),
            ),
            _buildCircleButton(
              icon: Icons.add,
              onPressed: () {
                setState(() {
                  controller?.text = (typedQty + 1).toString();
                });
              },
              color: accentColor,
            ),
            const SizedBox(width: 8),
            // Removed MAX button since there is no limit
            const SizedBox(width: 28),
          ],
        ),
      ],
    );
  }

  Widget _buildWholesalerSection(
    BuildContext context, 
    ThemeData theme, 
    AsyncValue<List<Collection>> collectionsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.business_outlined, size: 20, color: theme.colorScheme.secondary),
                  const SizedBox(width: 8),
                  Text(
                    'Détenteurs Externes (Grossistes & POS)',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => _addWholesalerCollection(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ajouter'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),
        collectionsAsync.when(
          data: (collections) {
            final externalCollections = collections.where((c) => c.type == CollectionType.wholesaler || c.type == CollectionType.pointOfSale).toList();
            if (externalCollections.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Aucune collecte externe (POS/Grossiste) ajoutée',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: externalCollections.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 40),
              itemBuilder: (context, index) {
                final collection = externalCollections[index];
                final isWholesaler = collection.type == CollectionType.wholesaler;
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 12,
                    backgroundColor: isWholesaler ? theme.colorScheme.secondaryContainer : theme.colorScheme.tertiaryContainer,
                    child: Text(
                      collection.clientName.characters.first.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isWholesaler ? theme.colorScheme.onSecondaryContainer : theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                  title: Text(
                    collection.clientName,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    collection.emptyBottles.entries
                        .map((e) => '${e.value} x ${e.key}kg')
                        .join(', '),
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: Text(
                    '${collection.totalEmptyBottles} btl',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isWholesaler ? theme.colorScheme.secondary : theme.colorScheme.tertiary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Erreur: $e', style: const TextStyle(color: Colors.red, fontSize: 10)),
          ),
        ),
      ],
    );
  }

  void _addWholesalerCollection(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => IndependentCollectionDialog(
        enterpriseId: widget.enterpriseId,
        tourId: widget.tour.id,
        // No initialType, let user choose between POS and Wholesaler
      ),
    );
  }
}
