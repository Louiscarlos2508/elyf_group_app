import 'package:elyf_groupe_app/shared/utils/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import '../../../domain/entities/cylinder.dart';
import '../../../domain/entities/point_of_sale.dart';

/// Dialog pour associer des types de bouteilles à un point de vente.
class PosAssociateCylindersDialog extends ConsumerStatefulWidget {
  const PosAssociateCylindersDialog({
    super.key,
    required this.pointOfSale,
    required this.enterpriseId,
    required this.moduleId,
    required this.dialogContext,
  });

  final PointOfSale pointOfSale;
  final String enterpriseId;
  final String moduleId;
  final BuildContext dialogContext;

  @override
  ConsumerState<PosAssociateCylindersDialog> createState() =>
      _PosAssociateCylindersDialogState();
}

class _PosAssociateCylindersDialogState
    extends ConsumerState<PosAssociateCylindersDialog> {
  late Set<String> _currentSelectedCylinderIds;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentSelectedCylinderIds = Set<String>.from(widget.pointOfSale.cylinderIds);
  }

  Future<void> _save() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (!mounted) return;

      final controller = ref.read(pointOfSaleControllerProvider);
      final updatedPos = widget.pointOfSale.copyWith(
        cylinderIds: _currentSelectedCylinderIds.toList(),
      );

      await controller.updatePointOfSale(updatedPos);

      if (!mounted) return;

      ref.invalidate(
        pointsOfSaleProvider(
          (enterpriseId: widget.enterpriseId, moduleId: widget.moduleId),
        ),
      );
      ref.invalidate(
        pointOfSaleCylindersProvider((
          pointOfSaleId: widget.pointOfSale.id,
          enterpriseId: widget.enterpriseId,
          moduleId: widget.moduleId,
        )),
      );

      if (!widget.dialogContext.mounted) return;
      Navigator.of(widget.dialogContext).pop();

      if (mounted) {
        NotificationService.showSuccess(context, 'Types associés avec succès');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (widget.dialogContext.mounted) {
        showDialog(
          context: widget.dialogContext,
          builder: (errorContext) => AlertDialog(
            title: const Text('Erreur'),
            content: Text(
              'Erreur lors de l\'enregistrement: ${e.toString()}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(errorContext).pop(),
                child: const Text('Fermer'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allCylindersAsync = ref.watch(cylindersProvider);

    return allCylindersAsync.when(
      data: (allCylinders) => AlertDialog(
        title: Text('Associer des types - ${widget.pointOfSale.name}'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 400),
          child: SizedBox(
            width: double.maxFinite,
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : allCylinders.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'Aucun type de bouteille disponible.\nCréez d\'abord des types dans les paramètres.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: allCylinders.length,
                        itemBuilder: (context, index) {
                          final cylinder = allCylinders[index];
                          final isSelected =
                              _currentSelectedCylinderIds.contains(cylinder.id);

                          return CheckboxListTile(
                            title: Text('${cylinder.weight}kg'),
                            subtitle: Text(
                              'Prix détail: ${cylinder.sellPrice.toStringAsFixed(0)} FCFA',
                            ),
                            value: isSelected,
                            onChanged: _isLoading
                                ? null
                                : (value) {
                                    setState(() {
                                      if (value == true) {
                                        _currentSelectedCylinderIds.add(cylinder.id);
                                      } else {
                                        _currentSelectedCylinderIds.remove(cylinder.id);
                                      }
                                    });
                                  },
                          );
                        },
                      ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading
                ? null
                : () => Navigator.of(widget.dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enregistrer'),
          ),
        ],
      ),
      loading: () => const AlertDialog(
        content: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => AlertDialog(
        title: const Text('Erreur'),
        content: Text('Erreur: $e'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(widget.dialogContext).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

