import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import '../../../domain/entities/wholesaler.dart';

/// Widget pour sélectionner un tour et un grossiste (pour ventes en gros).
///
/// Permet de :
/// - Sélectionner un tour
/// - Sélectionner un grossiste parmi ceux existants (tous les tours + ventes)
/// - Ajouter un nouveau grossiste
class TourWholesalerSelectorWidget extends ConsumerStatefulWidget {
  const TourWholesalerSelectorWidget({
    super.key,
    required this.enterpriseId,
    required this.onWholesalerChanged,
    this.selectedWholesalerId,
    this.selectedWholesalerName,
  });

  final String? selectedWholesalerId;
  final String? selectedWholesalerName;
  final String enterpriseId;
  final ValueChanged<({String id, String name, String tier})?> onWholesalerChanged;

  @override
  ConsumerState<TourWholesalerSelectorWidget> createState() =>
      _TourWholesalerSelectorWidgetState();
}

class _TourWholesalerSelectorWidgetState
    extends ConsumerState<TourWholesalerSelectorWidget> {
  final _wholesalerNameController = TextEditingController();
  final _wholesalerPhoneController = TextEditingController();
  final _wholesalerAddressController = TextEditingController();
  bool _isAddingNewWholesaler = false;

  @override
  void dispose() {
    _wholesalerNameController.dispose();
    _wholesalerPhoneController.dispose();
    _wholesalerAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allWholesalersAsync = ref.watch(
      allWholesalersProvider(widget.enterpriseId),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Information sur la source du stock (Dépôt ou POS)
        ref.watch(activeEnterpriseProvider).when(
          data: (enterprise) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outline.withAlpha(50)),
            ),
            child: Row(
              children: [
                Icon(
                  enterprise?.type == EnterpriseType.gasCompany 
                    ? Icons.warehouse_outlined 
                    : Icons.storefront_outlined,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Provenance du Gaz',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        enterprise?.name ?? 'Dépôt',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    enterprise?.type == EnterpriseType.gasCompany ? 'DÉPÔT / ENTREPÔT' : 'POINT DE VENTE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),

        // Sélection du grossiste (Toujours visible pour le gros)
        _buildWholesalerSelector(allWholesalersAsync),
      ],
    );
  }

  Widget _buildWholesalerSelector(
    AsyncValue<List<Wholesaler>> allWholesalersAsync,
  ) {
    final theme = Theme.of(context);
    return allWholesalersAsync.when(
      data: (allWholesalers) {
        // Si on est en mode ajout, afficher le formulaire
        if (_isAddingNewWholesaler) {
          return _buildNewWholesalerForm();
        }

        // Sinon, afficher la liste des grossistes avec option d'ajout
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: widget.selectedWholesalerId,
                dropdownColor: theme.colorScheme.surface,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  labelText: 'Trouver un Grossiste *',
                  labelStyle: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                  prefixIcon: Icon(Icons.business_center_outlined, color: theme.colorScheme.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.outline.withAlpha(50)),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerLow,
                ),
                items: [
                  ...allWholesalers.map((wholesaler) {
                    return DropdownMenuItem<String>(
                      value: wholesaler.id,
                      child: Text(wholesaler.name),
                    );
                  }),
                ],
                onChanged: (value) {
                  if (value != null) {
                    final wholesaler = allWholesalers.firstWhere((w) => w.id == value);
                    widget.onWholesalerChanged((
                      id: wholesaler.id,
                      name: wholesaler.name,
                      tier: wholesaler.tier,
                    ));
                  } else {
                    widget.onWholesalerChanged(null);
                  }
                },
                validator: (value) => value == null ? 'Veuillez sélectionner un grossiste' : null,
              ),
            ),
          ],
        ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _isAddingNewWholesaler = true;
                  widget.onWholesalerChanged(null);
                });
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter un nouveau grossiste'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.2)),
          ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Erreur de chargement des grossistes: $e',
                style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewWholesalerForm() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Nouveau grossiste - Les informations seront enregistrées',
                  style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _wholesalerNameController,
          decoration: const InputDecoration(
            labelText: 'Nom du grossiste *',
            prefixIcon: Icon(Icons.business),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le nom est requis';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _wholesalerPhoneController,
          decoration: const InputDecoration(
            labelText: 'Téléphone',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _wholesalerAddressController,
          decoration: const InputDecoration(
            labelText: 'Adresse',
            prefixIcon: Icon(Icons.location_on),
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isAddingNewWholesaler = false;
                    _wholesalerNameController.clear();
                    _wholesalerPhoneController.clear();
                    _wholesalerAddressController.clear();
                    widget.onWholesalerChanged(null);
                  });
                },
                child: const Text('Annuler'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  final name = _wholesalerNameController.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Le nom du grossiste est requis'),
                      ),
                    );
                    return;
                  }

                  // Générer un ID unique pour le nouveau grossiste
                  final newId = 'wholesaler_${DateTime.now().millisecondsSinceEpoch}';

                  // Notifier le parent avec le nouveau grossiste
                  widget.onWholesalerChanged((
                    id: newId,
                    name: name,
                    tier: 'default',
                  ));

                  // Réinitialiser le formulaire
                  setState(() {
                    _isAddingNewWholesaler = false;
                    _wholesalerNameController.clear();
                    _wholesalerPhoneController.clear();
                    _wholesalerAddressController.clear();
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Grossiste "$name" ajouté avec succès'),
                      backgroundColor: theme.colorScheme.primary,
                    ),
                  );
                },
                child: const Text('Ajouter'),
              ),
            ),
          ],
        ),
      ],
    );
  }

}
