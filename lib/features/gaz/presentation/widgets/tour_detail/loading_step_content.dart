import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/gaz/application/providers.dart' hide currentUserIdProvider;
import 'package:elyf_groupe_app/core/auth/providers.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/tour.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/cylinder.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/cylinder_stock.dart';
import 'package:elyf_groupe_app/features/gaz/domain/services/gaz_calculation_service.dart';

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
  final Map<int, TextEditingController> _controllers = {};
  Map<int, int> _nominalStocks = {};

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSettings(List<int> weights) async {
    final settingsAsync = await ref.read(gazSettingsControllerProvider).getSettings(
          enterpriseId: widget.enterpriseId,
          moduleId: 'gaz',
        );
    if (settingsAsync != null && mounted) {
      setState(() {
        _nominalStocks = settingsAsync.nominalStocks;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cylindersAsync = ref.watch(cylindersProvider);
    final emptyStocksAsync = ref.watch(gazStocksProvider);

    return cylindersAsync.when(
      data: (cylinders) {
        final weights = cylinders.map((c) => c.weight).toSet().toList()..sort();
        final allStocks = (emptyStocksAsync.value ?? [])
            .where((s) => s.enterpriseId == widget.enterpriseId && s.siteId == null)
            .toList();
        final emptyStocks = GazCalculationService.filterEmptyStocks(allStocks);
        
        // Initialize controllers for weights if not already present
        bool neededSettingsLoad = false;
        for (final weight in weights) {
          if (!_controllers.containsKey(weight)) {
            _controllers[weight] = TextEditingController(
              text: (widget.tour.emptyBottlesLoaded[weight] ?? 0).toString(),
            );
            neededSettingsLoad = true;
          }
        }

        if (neededSettingsLoad || _nominalStocks.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadSettings(weights);
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Indiquez les quantités de bouteilles vides à charger pour l\'échange.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            
            // Grid-like layout for weights
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.85,
              children: weights.map((weight) {
                final cylinderId = cylinders.any((Cylinder c) => c.weight == weight) 
                    ? cylinders.firstWhere((Cylinder c) => c.weight == weight).id 
                    : '';
                final atStoreQty = allStocks
                    .where((s) => s.cylinderId == cylinderId && s.status == CylinderStatus.emptyAtStore)
                    .fold<int>(0, (sum, s) => sum + s.quantity);
                final inTransitQty = allStocks
                    .where((s) => s.cylinderId == cylinderId && s.status == CylinderStatus.emptyInTransit)
                    .fold<int>(0, (sum, s) => sum + s.quantity);
                final availableQty = atStoreQty + inTransitQty;
                final nominal = _nominalStocks[weight] ?? 0;
                final controller = _controllers[weight];
                final typedQty = int.tryParse(controller?.text ?? '0') ?? 0;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: typedQty > 0 
                          ? theme.colorScheme.primary.withValues(alpha: 0.5)
                          : (isDark ? theme.colorScheme.outline.withValues(alpha: 0.2) : Colors.black12),
                      width: typedQty > 0 ? 1.5 : 1,
                    ),
                    boxShadow: [
                      if (!isDark && typedQty > 0)
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$weight kg',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: typedQty > 0 ? theme.colorScheme.primary : null,
                            ),
                          ),
                          if (availableQty > 0 && typedQty != availableQty)
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _controllers[weight]?.text = availableQty.toString();
                                });
                              },
                              icon: Icon(
                                Icons.add_circle_outline,
                                size: 18,
                                color: theme.colorScheme.secondary,
                              ),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Charger tout',
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: TextFormField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                          decoration: InputDecoration(
                            hintText: '0',
                            suffixText: 'btl',
                            suffixStyle: theme.textTheme.bodySmall,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Stock labels
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStockRow(
                            context, 
                            'Dépôt', 
                            atStoreQty, 
                            atStoreQty > 0 ? theme.colorScheme.primary : theme.colorScheme.error
                          ),
                          if (inTransitQty > 0)
                            _buildStockRow(
                              context, 
                              'Transit', 
                              inTransitQty, 
                              isDark ? Colors.orangeAccent : Colors.orange.shade700
                            ),
                          if (nominal > 0)
                            _buildStockRow(
                              context, 
                              'Objectif', 
                              nominal, 
                              theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                              isItalic: true
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 24),
            
            // Save Button with enhanced style
            FilledButton.icon(
              onPressed: () => _saveLoading(cylinders, emptyStocks),
              icon: const Icon(Icons.check_circle_outline, size: 20),
              label: const Text('Confirmer le Chargement'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
            
            // Summary Card
            if (widget.tour.emptyBottlesLoaded.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.local_shipping, size: 20, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chargement Actuel',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${widget.tour.totalBottlesToLoad} bouteilles prêtes pour l\'échange',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
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

  Future<void> _saveLoading(List<Cylinder> cylinders, List<CylinderStock> emptyStocks) async {
    final emptyBottles = <int, int>{};
    final errors = <String>[];

    for (final entry in _controllers.entries) {
      final weight = entry.key;
      final qty = int.tryParse(entry.value.text) ?? 0;
      
      final oldQty = widget.tour.emptyBottlesLoaded[weight] ?? 0;
      final delta = qty - oldQty;

      if (delta > 0) {
        // Validation du stock uniquement si on ajoute des bouteilles
        final cylinderId = cylinders.firstWhere((Cylinder c) => c.weight == weight).id;
        final availableInStore = emptyStocks
            .where((CylinderStock s) => s.cylinderId == cylinderId)
            .fold<int>(0, (int sum, CylinderStock s) => sum + s.quantity);

        if (delta > availableInStore) {
          errors.add('$weight kg : +$delta demandés, mais seulement $availableInStore en stock au magasin');
        }
      }
      
      if (qty > 0) {
        emptyBottles[weight] = qty;
      }
    }

    if (errors.isNotEmpty) {
      if (mounted) {
        NotificationService.showError(
          context,
          'Stock insuffisant :\n${errors.join('\n')}',
        );
      }
      return;
    }

    if (emptyBottles.isEmpty) {
      if (mounted) {
        NotificationService.showError(
          context,
          'Saisissez au moins une quantité',
        );
      }
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
      );

      if (mounted) {
        NotificationService.showSuccess(
          context,
          'Chargement enregistré',
        );
        ref.invalidate(tourProvider(widget.tour.id));
        widget.onSaved?.call();
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, 'Erreur: $e');
      }
    }
  }

  Widget _buildStockRow(BuildContext context, String label, int value, Color color, {bool isItalic = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontSize: 10,
              fontStyle: isItalic ? FontStyle.italic : null,
            ),
          ),
          Text(
            value.toString(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
