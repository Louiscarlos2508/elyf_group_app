import 'package:elyf_groupe_app/shared/utils/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared/presentation/widgets/elyf_ui/atoms/elyf_button.dart';

import 'package:elyf_groupe_app/features/administration/application/providers.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';

/// Dialog pour associer des types de bouteilles à un point de vente.
class PosAssociateCylindersDialog extends ConsumerStatefulWidget {
  const PosAssociateCylindersDialog({
    super.key,
    required this.enterprise,
    required this.enterpriseId,
    required this.moduleId,
    required this.dialogContext,
  });

  final Enterprise enterprise;
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
    final cylinderIds = widget.enterprise.metadata['cylinderIds'] as List<dynamic>? ?? [];
    _currentSelectedCylinderIds = Set<String>.from(cylinderIds.map((e) => e.toString()));
  }

  Future<void> _save() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (!mounted) return;

      final controller = ref.read(enterpriseControllerProvider);
      
      final currentMetadata = Map<String, dynamic>.from(widget.enterprise.metadata);
      currentMetadata['cylinderIds'] = _currentSelectedCylinderIds.toList();
      
      final updatedPos = widget.enterprise.copyWith(
        metadata: currentMetadata,
      );

      await controller.updateEnterprise(updatedPos);

      if (!mounted) return;

      ref.invalidate(
        enterprisesByParentAndTypeProvider((
          parentId: widget.enterpriseId,
          type: EnterpriseType.gasPointOfSale,
        )),
      );
      ref.invalidate(
        pointOfSaleCylindersProvider((
          pointOfSaleId: widget.enterprise.id,
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
            content: Text('Erreur lors de l\'enregistrement: ${e.toString()}'),
            actions: [
              ElyfButton(
                onPressed: () => Navigator.of(errorContext).pop(),
                variant: ElyfButtonVariant.text,
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
        title: Text('Associer des types - ${widget.enterprise.name}'),
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
                      final isSelected = _currentSelectedCylinderIds.contains(
                        cylinder.id,
                      );

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
                                    _currentSelectedCylinderIds.add(
                                      cylinder.id,
                                    );
                                  } else {
                                    _currentSelectedCylinderIds.remove(
                                      cylinder.id,
                                    );
                                  }
                                });
                              },
                      );
                    },
                  ),
          ),
        ),
        actions: [
          ElyfButton(
            onPressed: _isLoading
                ? null
                : () => Navigator.of(widget.dialogContext).pop(),
            variant: ElyfButtonVariant.text,
            child: const Text('Annuler'),
          ),
          ElyfButton(
            onPressed: _isLoading ? null : _save,
            isLoading: _isLoading,
            child: const Text('Enregistrer'),
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
          ElyfButton(
            onPressed: () => Navigator.of(widget.dialogContext).pop(),
            variant: ElyfButtonVariant.text,
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
