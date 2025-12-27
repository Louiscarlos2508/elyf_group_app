import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../application/providers.dart';
import '../../../../domain/entities/gaz_settings.dart';

/// Ligne d'édition de prix pour un poids de bouteille.
class WholesalePriceRow extends ConsumerStatefulWidget {
  const WholesalePriceRow({
    super.key,
    required this.weight,
    required this.price,
    required this.settings,
    required this.enterpriseId,
    required this.moduleId,
    required this.onPriceSaved,
  });

  final int weight;
  final double price;
  final GazSettings? settings;
  final String enterpriseId;
  final String moduleId;
  final VoidCallback onPriceSaved;

  @override
  ConsumerState<WholesalePriceRow> createState() => _WholesalePriceRowState();
}

class _WholesalePriceRowState extends ConsumerState<WholesalePriceRow> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.price > 0 ? widget.price.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _savePrice() async {
    final text = _controller.text.replaceAll(' ', '');
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
        weight: widget.weight,
        price: price,
      );

      if (mounted) {
        ref.invalidate(
          gazSettingsProvider(
            (enterpriseId: widget.enterpriseId, moduleId: widget.moduleId),
          ),
        );

        setState(() {
          _isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prix en gros enregistré avec succès'),
            backgroundColor: Colors.green,
          ),
        );

        widget.onPriceSaved();
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

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      final prevPrice = widget.settings?.getWholesalePrice(widget.weight) ?? 0.0;
      _controller.text = prevPrice > 0 ? prevPrice.toStringAsFixed(0) : '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
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
              '${widget.weight}kg',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Champ de prix
          Expanded(
            child: _isEditing
                ? TextFormField(
                    controller: _controller,
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
                    onFieldSubmitted: (_) => _savePrice(),
                  )
                : InkWell(
                    onTap: () {
                      setState(() {
                        _isEditing = true;
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
                              widget.price > 0
                                  ? '${numberFormat.format(widget.price.toInt())} FCFA'
                                  : 'Cliquez pour définir le prix',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: widget.price > 0
                                    ? colors.onSurface
                                    : colors.onSurfaceVariant,
                                fontWeight: widget.price > 0
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
          if (_isEditing) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.check),
              color: Colors.green,
              onPressed: _savePrice,
              tooltip: 'Enregistrer',
            ),
            IconButton(
              icon: const Icon(Icons.close),
              color: colors.error,
              onPressed: _cancelEdit,
              tooltip: 'Annuler',
            ),
          ],
        ],
      ),
    );
  }
}

