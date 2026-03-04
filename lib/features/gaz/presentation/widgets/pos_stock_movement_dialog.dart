import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../domain/entities/cylinder.dart';
import '../../application/providers.dart';
import '../../../../../../core/errors/error_handler.dart';
import '../../../../../../core/logging/app_logger.dart';
import 'collection_form/bottle_list_display.dart';
import 'collection_form/bottle_manager.dart';
import 'collection_form/bottle_quantity_input.dart';
import '../../../../../../core/auth/providers.dart';

enum PosMovementType { fullEntry, emptyEntry, emptyExit }

/// Dialog for POS manual stock movements.
class PosStockMovementDialog extends ConsumerStatefulWidget {
  const PosStockMovementDialog({
    super.key,
    required this.enterpriseId,
    required this.movementType,
  });

  final String enterpriseId;
  final PosMovementType movementType;

  @override
  ConsumerState<PosStockMovementDialog> createState() => _PosStockMovementDialogState();
}

class _PosStockMovementDialogState extends ConsumerState<PosStockMovementDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<int, int> _bottles = {}; // weight -> quantity
  final _notesController = TextEditingController();

  // For adding bottles
  int? _selectedWeight;
  final _quantityController = TextEditingController(text: '0');

  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _addBottle() {
    BottleManager.addBottle(
      context: context,
      selectedWeight: _selectedWeight,
      quantityText: _quantityController.text,
      bottles: _bottles,
      maxQuantity: 999999, // No strict limit for manual POS movements
      onBottlesChanged: () {
        setState(() {
          _selectedWeight = null;
          _quantityController.text = '0';
        });
      },
    );
  }

  void _removeBottle(int weight) {
    BottleManager.removeBottle(
      weight: weight,
      bottles: _bottles,
      onBottlesChanged: () => setState(() {}),
    );
  }

  Future<void> _submit() async {
    if (_bottles.isEmpty) {
      NotificationService.showInfo(context, 'Ajoutez au moins une bouteille');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authController = ref.read(authControllerProvider);
      final userId = authController.currentUser?.id ?? 'system';
      final activeEnterprise = ref.read(activeEnterpriseProvider).value;
      final siteId = activeEnterprise?.isPointOfSale == true ? activeEnterprise?.id : null;

      final transactionService = ref.read(transactionServiceProvider);
      
      Map<int, int> fullEntries = {};
      Map<int, int> emptyEntries = {};
      Map<int, int> emptyExits = {};

      switch (widget.movementType) {
        case PosMovementType.fullEntry:
          fullEntries = _bottles;
          break;
        case PosMovementType.emptyEntry:
          emptyEntries = _bottles;
          break;
        case PosMovementType.emptyExit:
          emptyExits = _bottles;
          break;
      }

      await transactionService.executePosStockMovement(
        enterpriseId: widget.enterpriseId,
        siteId: siteId,
        userId: userId,
        fullEntries: fullEntries,
        emptyEntries: emptyEntries,
        emptyExits: emptyExits,
        notes: _notesController.text,
      );

      if (!mounted) return;

      NotificationService.showSuccess(
        context,
        'Mouvement enregistré avec succès',
      );

      // Invalidate providers
      ref.invalidate(cylinderStocksProvider((
        enterpriseId: widget.enterpriseId,
        status: null,
        siteId: null, // this works as a wildcard or re-fetch trigger if correctly tuned in provider
      )));

      Navigator.of(context).pop();
    } catch (e, stackTrace) {
      if (!mounted) return;
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Erreur lors du mouvement de stock POS: ${appException.message}',
        name: 'gaz.pos_movement',
        error: e,
        stackTrace: stackTrace,
      );
      NotificationService.showError(
        context,
        ErrorHandler.instance.getUserMessage(appException),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  List<int> _getAvailableWeights(WidgetRef ref) {
    final cylindersAsync = ref.watch(cylindersProvider);
    return cylindersAsync.when(
      data: (cylinders) {
        final weights = cylinders.map((c) => c.weight).toSet().toList();
        weights.sort();
        return weights;
      },
      loading: () => [],
      error: (_, __) => [],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final availableWeights = _getAvailableWeights(ref);

    String title;
    String description;
    String submitLabel;
    IconData icon;
    Color iconColor;

    switch (widget.movementType) {
      case PosMovementType.fullEntry:
        title = 'Approvisionnement (Pleins)';
        description = 'Enregistrez la réception de bouteilles pleines dans votre stock.';
        submitLabel = 'Confirmer l\'entrée (Pleins)';
        icon = Icons.download_rounded;
        iconColor = AppColors.success;
        break;
      case PosMovementType.emptyEntry:
        title = 'Retour de Vides (Client)';
        description = 'Enregistrez l\'entrée de bouteilles vides ramenées par les clients indépendamment d\'une vente.';
        submitLabel = 'Confirmer l\'entrée (Vides)';
        icon = Icons.assignment_return_rounded;
        iconColor = theme.colorScheme.tertiary;
        break;
      case PosMovementType.emptyExit:
        title = 'Envoi au Rechargement (Vides)';
        description = 'Enregistrez le départ de bouteilles vides pour rechargement.';
        submitLabel = 'Confirmer la sortie (Vides)';
        icon = Icons.upload_rounded;
        iconColor = AppColors.warning;
        break;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: iconColor,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_bottles.isNotEmpty) ...[
                        BottleListDisplay(
                          bottles: _bottles,
                          onRemove: _removeBottle,
                        ),
                        const SizedBox(height: 16),
                      ],
                      BottleQuantityInput(
                        availableWeights: availableWeights,
                        selectedWeight: _selectedWeight,
                        quantityController: _quantityController,
                        onWeightSelected: (weight) => setState(() => _selectedWeight = weight),
                        onAdd: _addBottle,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Notes / Justification (Optionnel)',
                          hintText: 'Ex: Arrivée camion, Retour dépôt...',
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 8),
                  ElyfButton(
                    onPressed: _bottles.isNotEmpty ? _submit : null,
                    isLoading: _isSubmitting,
                    child: Text(submitLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

