import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../domain/entities/cylinder.dart';
import '../../application/providers.dart';
import '../../../../../../core/errors/error_handler.dart';
import '../../../../../../core/logging/app_logger.dart';
import '../../../../../../core/auth/providers.dart';

/// Type de mouvement de stock POS.
/// - [entry] : Entrée groupée (bouteilles pleines + bouteilles vides retour fournisseur non rechargées)
/// - [emptyExit] : Sortie de bouteilles vides pour rechargement chez le fournisseur
enum PosMovementType { entry, emptyExit }

/// Dialog for POS manual stock movements.
/// 
/// Pour les entrées ([PosMovementType.entry]), l'utilisateur peut saisir :
/// - Des bouteilles **pleines** reçues du fournisseur
/// - Des bouteilles **vides** retournées non-rechargées (pertes de tournée)
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
  // Bouteilles pleines (entrée uniquement)
  final Map<int, int> _fullBottles = {};
  // Bouteilles vides (retour fournisseur non-rechargé pour entrée, ou sortie rechargement)
  final Map<int, int> _emptyBottles = {};
  final _notesController = TextEditingController();

  int? _selectedFullWeight;
  int? _selectedEmptyWeight;
  final _fullQuantityController = TextEditingController(text: '0');
  final _emptyQuantityController = TextEditingController(text: '0');

  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    _fullQuantityController.dispose();
    _emptyQuantityController.dispose();
    super.dispose();
  }

  List<int> _getAvailableWeights() {
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

  void _addFull() {
    final weight = _selectedFullWeight;
    final qty = int.tryParse(_fullQuantityController.text) ?? 0;
    if (weight == null) {
      NotificationService.showInfo(context, 'Sélectionnez un poids');
      return;
    }
    if (qty <= 0) {
      NotificationService.showInfo(context, 'La quantité doit être > 0');
      return;
    }
    setState(() {
      _fullBottles[weight] = (_fullBottles[weight] ?? 0) + qty;
      _selectedFullWeight = null;
      _fullQuantityController.text = '0';
    });
  }

  void _addEmpty() {
    final weight = _selectedEmptyWeight;
    final qty = int.tryParse(_emptyQuantityController.text) ?? 0;
    if (weight == null) {
      NotificationService.showInfo(context, 'Sélectionnez un poids');
      return;
    }
    if (qty <= 0) {
      NotificationService.showInfo(context, 'La quantité doit être > 0');
      return;
    }
    setState(() {
      _emptyBottles[weight] = (_emptyBottles[weight] ?? 0) + qty;
      _selectedEmptyWeight = null;
      _emptyQuantityController.text = '0';
    });
  }

  bool get _hasAnyBottles {
    if (widget.movementType == PosMovementType.entry) {
      return _fullBottles.isNotEmpty || _emptyBottles.isNotEmpty;
    }
    return _emptyBottles.isNotEmpty;
  }

  Future<void> _submit() async {
    if (!_hasAnyBottles) {
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

      // Check for mismatches to add a note
      String finalNotes = _notesController.text;
      if (widget.movementType == PosMovementType.entry) {
        final stocks = ref.read(gazStocksProvider).value ?? [];
        final inTransit = stocks.where((s) => s.status == CylinderStatus.emptyInTransit).toList();
        
        List<String> mismatches = [];
        for (final item in inTransit) {
          final received = (_fullBottles[item.weight] ?? 0) + (_emptyBottles[item.weight] ?? 0);
          if (received != item.quantity) {
            mismatches.add('${item.weight}kg: reçu $received, attendu ${item.quantity}');
          }
        }
        
        if (mismatches.isNotEmpty) {
          finalNotes += '\n[Écart constaté à l\'entrée : ${mismatches.join(", ")}]';
        }
      }

      await transactionService.executePosStockMovement(
        enterpriseId: widget.enterpriseId,
        siteId: siteId,
        userId: userId,
        fullEntries: widget.movementType == PosMovementType.entry ? _fullBottles : {},
        emptyEntries: widget.movementType == PosMovementType.entry ? _emptyBottles : {},
        emptyExits: widget.movementType == PosMovementType.emptyExit ? _emptyBottles : {},
        notes: finalNotes,
      );

      if (!mounted) return;
      NotificationService.showSuccess(context, 'Mouvement enregistré avec succès');
      ref.invalidate(cylinderStocksProvider);
      ref.invalidate(gazStocksProvider);
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
      NotificationService.showError(context, ErrorHandler.instance.getUserMessage(appException));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final availableWeights = _getAvailableWeights();

    final String title;
    final String description;
    final String submitLabel;
    final IconData icon;
    final Color iconColor;

    if (widget.movementType == PosMovementType.entry) {
      title = 'Entrée de Stock';
      description = 'Enregistrez la réception de bouteilles depuis le fournisseur : pleines rechargées et vides non-rechargées (retours partiels).';
      submitLabel = 'Confirmer l\'entrée';
      icon = Icons.download_rounded;
      iconColor = AppColors.success;
    } else {
      title = 'Sortie – Envoi Rechargement';
      description = 'Enregistrez le départ de bouteilles vides pour rechargement chez le fournisseur.';
      submitLabel = 'Confirmer la sortie (Vides)';
      icon = Icons.upload_rounded;
      iconColor = AppColors.warning;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(description, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Section Pending Refills (Entrée uniquement)
                      if (widget.movementType == PosMovementType.entry) ...[
                        _buildPendingRefillsSection(theme),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                      ],

                      // Section Pleins (Entrée uniquement)
                      if (widget.movementType == PosMovementType.entry) ...[
                        _SectionTitle(
                          icon: Icons.inventory_2_rounded,
                          color: AppColors.success,
                          label: 'Bouteilles Pleines reçues',
                        ),
                        const SizedBox(height: 8),
                        _BottleInputRow(
                          availableWeights: availableWeights,
                          selectedWeight: _selectedFullWeight,
                          quantityController: _fullQuantityController,
                          onWeightSelected: (w) => setState(() => _selectedFullWeight = w),
                          onAdd: _addFull,
                          accentColor: AppColors.success,
                        ),
                        if (_fullBottles.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _BottleSummaryChips(
                            bottles: _fullBottles,
                            color: AppColors.success,
                            onRemove: (w) => setState(() => _fullBottles.remove(w)),
                          ),
                        ],
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),

                        _SectionTitle(
                          icon: Icons.assignment_return_rounded,
                          color: theme.colorScheme.tertiary,
                          label: 'Vides retournés non-rechargés',
                          subtitle: 'Bouteilles envoyées mais non-chargées',
                        ),
                        const SizedBox(height: 8),
                        _BottleInputRow(
                          availableWeights: availableWeights,
                          selectedWeight: _selectedEmptyWeight,
                          quantityController: _emptyQuantityController,
                          onWeightSelected: (w) => setState(() => _selectedEmptyWeight = w),
                          onAdd: _addEmpty,
                          accentColor: theme.colorScheme.tertiary,
                        ),
                        if (_emptyBottles.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _BottleSummaryChips(
                            bottles: _emptyBottles,
                            color: theme.colorScheme.tertiary,
                            onRemove: (w) => setState(() => _emptyBottles.remove(w)),
                          ),
                        ],
                      ],

                      // Section Sortie Vides
                      if (widget.movementType == PosMovementType.emptyExit) ...[
                        _SectionTitle(
                          icon: Icons.upload_rounded,
                          color: AppColors.warning,
                          label: 'Bouteilles Vides à envoyer',
                        ),
                        const SizedBox(height: 8),
                        _BottleInputRow(
                          availableWeights: availableWeights,
                          selectedWeight: _selectedEmptyWeight,
                          quantityController: _emptyQuantityController,
                          onWeightSelected: (w) => setState(() => _selectedEmptyWeight = w),
                          onAdd: _addEmpty,
                          accentColor: AppColors.warning,
                        ),
                        if (_emptyBottles.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _BottleSummaryChips(
                            bottles: _emptyBottles,
                            color: AppColors.warning,
                            onRemove: (w) => setState(() => _emptyBottles.remove(w)),
                          ),
                        ],
                      ],

                      const SizedBox(height: 16),
                      TextField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Notes / Justification (Optionnel)',
                          hintText: 'Ex: Arrivée camion, fournisseur X...',
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 8),
                  ElyfButton(
                    onPressed: _hasAnyBottles ? _submit : null,
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
  Widget _buildPendingRefillsSection(ThemeData theme) {
    final stocksAsync = ref.watch(gazStocksProvider);
    
    return stocksAsync.when(
      data: (stocks) {
        final inTransit = stocks
            .where((s) => s.status == CylinderStatus.emptyInTransit && s.quantity > 0)
            .toList();

        if (inTransit.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 12),
                const Expanded(child: Text('Aucune bouteille vide n\'est actuellement en attente de recharge chez le fournisseur.')),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _SectionTitle(
                    icon: Icons.local_shipping_outlined,
                    color: theme.colorScheme.primary,
                    label: 'En attente de recharge',
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      for (final s in inTransit) {
                        _fullBottles[s.weight] = s.quantity;
                        _emptyBottles.remove(s.weight);
                      }
                    });
                  },
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('Tout remplir'),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: inTransit.map((s) {
                final received = (_fullBottles[s.weight] ?? 0) + (_emptyBottles[s.weight] ?? 0);
                final hasMismatch = received != s.quantity && received > 0;
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: (hasMismatch ? Colors.orange : theme.colorScheme.primary).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: (hasMismatch ? Colors.orange : theme.colorScheme.primary).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${s.weight}kg : ', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('${s.quantity} attendus', style: TextStyle(color: theme.colorScheme.primary)),
                      if (hasMismatch) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
      loading: () => const Center(child: LinearProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.color,
    required this.label,
    this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
              if (subtitle != null)
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}

class _BottleInputRow extends StatelessWidget {
  const _BottleInputRow({
    required this.availableWeights,
    required this.selectedWeight,
    required this.quantityController,
    required this.onWeightSelected,
    required this.onAdd,
    required this.accentColor,
  });

  final List<int> availableWeights;
  final int? selectedWeight;
  final TextEditingController quantityController;
  final ValueChanged<int?> onWeightSelected;
  final VoidCallback onAdd;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            value: selectedWeight,
            decoration: const InputDecoration(
              labelText: 'Poids',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: availableWeights.map((w) => DropdownMenuItem(value: w, child: Text('$w kg'))).toList(),
            onChanged: onWeightSelected,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: TextField(
            controller: quantityController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              labelText: 'Qté',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 18),
          style: IconButton.styleFrom(backgroundColor: accentColor),
        ),
      ],
    );
  }
}

class _BottleSummaryChips extends StatelessWidget {
  const _BottleSummaryChips({
    required this.bottles,
    required this.color,
    required this.onRemove,
  });

  final Map<int, int> bottles;
  final Color color;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: bottles.entries.map((e) {
        return Chip(
          label: Text('${e.key}kg × ${e.value}', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          backgroundColor: color.withValues(alpha: 0.1),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
          deleteIcon: Icon(Icons.close, size: 14, color: color),
          onDeleted: () => onRemove(e.key),
        );
      }).toList(),
    );
  }
}
