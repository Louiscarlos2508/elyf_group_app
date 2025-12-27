import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/providers.dart';
import '../../domain/entities/cylinder.dart';
import '../../domain/entities/gaz_settings.dart';

/// Carte de configuration des prix en gros dans les paramètres.
class WholesalePriceConfigCard extends ConsumerStatefulWidget {
  const WholesalePriceConfigCard({
    super.key,
    required this.enterpriseId,
    required this.moduleId,
  });

  final String enterpriseId;
  final String moduleId;

  @override
  ConsumerState<WholesalePriceConfigCard> createState() =>
      _WholesalePriceConfigCardState();
}

class _WholesalePriceConfigCardState
    extends ConsumerState<WholesalePriceConfigCard> {
  final Map<int, TextEditingController> _priceControllers = {};
  final Map<int, bool> _isEditing = {};

  @override
  void dispose() {
    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeControllers(GazSettings? settings) {
    for (final weight in CylinderWeight.availableWeights) {
      if (!_priceControllers.containsKey(weight)) {
        final price = settings?.getWholesalePrice(weight) ?? 0.0;
        _priceControllers[weight] = TextEditingController(
          text: price > 0 ? price.toStringAsFixed(0) : '',
        );
        _isEditing[weight] = false;
      } else {
        // Mettre à jour si les paramètres ont changé
        final price = settings?.getWholesalePrice(weight) ?? 0.0;
        if (price > 0 && _priceControllers[weight]!.text.isEmpty) {
          _priceControllers[weight]!.text = price.toStringAsFixed(0);
        }
      }
    }
  }

  Future<void> _savePrice(int weight) async {
    final controller = _priceControllers[weight]!;
    final text = controller.text.replaceAll(' ', '');
    final price = double.tryParse(text) ?? 0.0;

    if (price <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le prix doit être supérieur à 0'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final settingsController = ref.read(gazSettingsControllerProvider);
      await settingsController.setWholesalePrice(
        enterpriseId: widget.enterpriseId,
        moduleId: widget.moduleId,
        weight: weight,
        price: price,
      );

      if (mounted) {
        ref.invalidate(
          gazSettingsProvider(
            (enterpriseId: widget.enterpriseId, moduleId: widget.moduleId),
          ),
        );

        setState(() {
          _isEditing[weight] = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prix en gros enregistré avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final settingsAsync = ref.watch(
      gazSettingsProvider(
        (enterpriseId: widget.enterpriseId, moduleId: widget.moduleId),
      ),
    );

    return settingsAsync.when(
      data: (settings) {
        _initializeControllers(settings);

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: colors.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.price_check,
                        color: colors.onPrimaryContainer,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prix en Gros',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Définissez les prix en gros par poids de bouteille pour les tours',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Liste des prix par poids
                ...CylinderWeight.availableWeights.map((weight) {
                  final isEditing = _isEditing[weight] ?? false;
                  final price = settings?.getWholesalePrice(weight) ?? 0.0;
                  final numberFormat = NumberFormat('#,###', 'fr_FR');

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.outline.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Poids
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${weight}kg',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Champ de prix
                        Expanded(
                          child: isEditing
                              ? TextFormField(
                                  controller: _priceControllers[weight],
                                  keyboardType: const TextInputType.numberWithOptions(
                                    decimal: false,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: InputDecoration(
                                    labelText: 'Prix en gros (FCFA)',
                                    hintText: 'Entrez le prix',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.attach_money),
                                  ),
                                  onFieldSubmitted: (_) => _savePrice(weight),
                                )
                              : InkWell(
                                  onTap: () {
                                    setState(() {
                                      _isEditing[weight] = true;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.surface,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: colors.outline.withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.attach_money,
                                          size: 20,
                                          color: colors.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            price > 0
                                                ? '${numberFormat.format(price.toInt())} FCFA'
                                                : 'Cliquez pour définir le prix',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: price > 0
                                                  ? colors.onSurface
                                                  : colors.onSurfaceVariant,
                                              fontWeight: price > 0
                                                  ? FontWeight.w500
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.edit_outlined,
                                          size: 18,
                                          color: colors.onSurfaceVariant,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                        if (isEditing) ...[
                          const SizedBox(width: 8),
                          // Bouton sauvegarder
                          IconButton(
                            icon: const Icon(Icons.check),
                            color: Colors.green,
                            onPressed: () => _savePrice(weight),
                            tooltip: 'Enregistrer',
                          ),
                          // Bouton annuler
                          IconButton(
                            icon: const Icon(Icons.close),
                            color: colors.error,
                            onPressed: () {
                              setState(() {
                                _isEditing[weight] = false;
                                // Restaurer la valeur précédente
                                final prevPrice =
                                    settings?.getWholesalePrice(weight) ?? 0.0;
                                _priceControllers[weight]!.text =
                                    prevPrice > 0 ? prevPrice.toStringAsFixed(0) : '';
                              });
                            },
                            tooltip: 'Annuler',
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.error_outline, color: colors.error, size: 48),
              const SizedBox(height: 16),
              Text(
                'Erreur lors du chargement des paramètres',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

