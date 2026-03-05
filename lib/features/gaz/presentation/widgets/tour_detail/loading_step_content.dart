import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/gaz/application/providers.dart' hide currentUserIdProvider;
import 'package:elyf_groupe_app/core/auth/providers.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/tour.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/cylinder.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/wholesaler.dart';
import 'package:elyf_groupe_app/features/administration/application/providers.dart' as admin_providers;
import 'package:elyf_groupe_app/features/gaz/presentation/widgets/wholesaler_form_dialog.dart';

/// Contenu de l'étape Chargement du tour (Vides uniquement).
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
  late List<TourLoadingSource> _loadingSources;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _loadingSources = List.from(widget.tour.loadingSources);
    if (_loadingSources.isEmpty) {
      // Add a default entry if empty? Or just let user add.
    }
    _initialized = true;
  }

  @override
  void didUpdateWidget(LoadingStepContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tour.id != oldWidget.tour.id) {
      setState(() {
        _loadingSources = List.from(widget.tour.loadingSources);
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _addSource(TourLoadingSourceType type) {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          if (type == TourLoadingSourceType.pos) {
            final posAsync = ref.watch(admin_providers.enterprisesByParentAndTypeProvider((
              parentId: widget.enterpriseId,
              type: EnterpriseType.gasPointOfSale,
            )));
            return posAsync.when(
              data: (posList) => _buildSelectionDialog(
                context,
                title: 'Choisir un Point de Vente',
                items: posList.map((e) => (id: e.id, name: e.name)).toList(),
                type: type,
              ),
              loading: () => const AlertDialog(
                content: SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
              ),
              error: (e, _) => AlertDialog(title: const Text('Erreur'), content: Text('$e')),
            );
          } else {
            final wholesalersAsync = ref.watch(wholesalersProvider);
            return wholesalersAsync.when(
              data: (wholesalers) => _buildSelectionDialog(
                context,
                title: 'Choisir un Grossiste',
                items: wholesalers.map((w) => (id: w.id, name: w.name)).toList(),
                type: type,
              ),
              loading: () => const AlertDialog(
                content: SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
              ),
              error: (e, _) => AlertDialog(title: const Text('Erreur'), content: Text('$e')),
            );
          }
        },
      ),
    );
  }

  Widget _buildSelectionDialog(
    BuildContext context, {
    required String title,
    required List<({String id, String name})> items,
    required TourLoadingSourceType type,
  }) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (type == TourLoadingSourceType.wholesaler) ...[
              ListTile(
                leading: const Icon(Icons.add_circle_outline, color: Colors.blue),
                title: const Text('Créer un nouveau grossiste', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                onTap: () async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (context) => WholesalerFormDialog(enterpriseId: widget.enterpriseId),
                  );
                  if (result == true && mounted) {
                    ref.invalidate(wholesalersProvider);
                    Navigator.pop(context);
                    // Re-open dialog to see the new one? Or automatically add it?
                    // Let's re-open by calling _addSource again on next frame or just let user re-click.
                    // Better: just Navigator.pop and let them re-click.
                  }
                },
              ),
              const Divider(),
            ],
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Aucun élément trouvé', textAlign: TextAlign.center),
              )
            else
              Flexible(
                child: Scrollbar(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        title: Text(item.name),
                        trailing: const Icon(Icons.chevron_right, size: 18),
                        onTap: () {
                          setState(() {
                            if (!_loadingSources.any((s) => s.id == item.id)) {
                              _loadingSources.add(TourLoadingSource(
                                id: item.id,
                                type: type,
                                sourceName: item.name,
                                quantities: {},
                              ));
                            }
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cylindersAsync = ref.watch(cylindersProvider);

    return cylindersAsync.when(
      data: (cylinders) {
        final weights = cylinders.map((c) => c.weight).toSet().toList()..sort();

        return Column(
          children: [
            // Header & Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Multi-Sources : Chargement Vides',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<TourLoadingSourceType>(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Ajouter une source',
                    onSelected: _addSource,
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: TourLoadingSourceType.pos,
                        child: Text('Ajouter Point de Vente'),
                      ),
                      const PopupMenuItem(
                        value: TourLoadingSourceType.wholesaler,
                        child: Text('Ajouter Grossiste'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (_loadingSources.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.add_business_outlined, size: 48, color: theme.colorScheme.outline),
                      const SizedBox(height: 12),
                      Text(
                        'Aucune source de chargement ajoutée',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () => _addSource(TourLoadingSourceType.pos),
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter un Point de Vente'),
                      ),
                    ],
                  ),
                ),
              ),

            // Source Cards
            ...List.generate(_loadingSources.length, (sourceIndex) {
              final source = _loadingSources[sourceIndex];
              return Card(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: Column(
                  children: [
                    ListTile(
                      dense: true,
                      leading: Icon(
                        source.type == TourLoadingSourceType.pos ? Icons.storefront : Icons.factory_outlined,
                        color: theme.colorScheme.secondary,
                      ),
                      title: Text(
                        source.sourceName,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(source.type == TourLoadingSourceType.pos ? 'Point de Vente' : 'Grossiste'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => setState(() => _loadingSources.removeAt(sourceIndex)),
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: weights.map((weight) {
                          final qty = source.quantities[weight] ?? 0;
                          return IntrinsicWidth(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${weight}kg',
                                    style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 12),
                                  _buildQtyActions(
                                    context: context,
                                    qty: qty,
                                    onChanged: (newQty) {
                                      setState(() {
                                        final updatedQuantities = Map<int, int>.from(source.quantities);
                                        if (newQty > 0) {
                                          updatedQuantities[weight] = newQty;
                                        } else {
                                          updatedQuantities.remove(weight);
                                        }
                                        _loadingSources[sourceIndex] = source.copyWith(quantities: updatedQuantities);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 32),
            
            // Validation button
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: _loadingSources.isEmpty ? null : _saveLoading,
                icon: const Icon(Icons.local_shipping_outlined, size: 20),
                label: const Text('Valider le chargement'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
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
        child: Text('Erreur: $e'),
      ),
    );
  }

  Widget _buildQtyActions({
    required BuildContext context,
    required int qty,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: qty > 0 ? () => onChanged(qty - 1) : null,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: qty > 0 ? Colors.grey.withOpacity(0.2) : Colors.transparent,
            ),
            child: Icon(Icons.remove, size: 16, color: qty > 0 ? null : Colors.grey),
          ),
        ),
        GestureDetector(
          onTap: () => _showManualQtyDialog(context, qty, onChanged),
          child: Container(
            width: 48,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              qty.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        GestureDetector(
          onTap: () => onChanged(qty + 1),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.withOpacity(0.2),
            ),
            child: const Icon(Icons.add, size: 16),
          ),
        ),
      ],
    );
  }

  Future<void> _showManualQtyDialog(BuildContext context, int initialValue, ValueChanged<int> onChanged) async {
    final controller = TextEditingController(text: initialValue.toString());
    final result = await showDialog<int?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saisir la quantité'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nombre de bouteilles',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (val) {
            final parsed = int.tryParse(val);
            Navigator.pop(context, parsed);
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text);
              Navigator.pop(context, parsed);
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );

    if (result != null && result >= 0) {
      onChanged(result);
    }
  }

  Future<void> _saveLoading() async {
    if (_loadingSources.isEmpty) {
       NotificationService.showError(context, 'Ajoutez au moins une source de chargement');
       return;
    }

    try {
      final controller = ref.read(tourControllerProvider);
      final userId = ref.read(currentUserIdProvider);

      if (userId == null) {
        NotificationService.showError(context, 'Utilisateur non identifié');
        return;
      }

      await controller.updateEmptyBottlesLoaded(
        widget.tour.id,
        _loadingSources,
        userId,
      );

      if (mounted) {
        NotificationService.showSuccess(context, 'Chargement multi-sources enregistré');
        ref.invalidate(tourProvider(widget.tour.id));
        widget.onSaved?.call();
      }
    } catch (e) {
      if (mounted) NotificationService.showError(context, 'Erreur: $e');
    }
  }
}
