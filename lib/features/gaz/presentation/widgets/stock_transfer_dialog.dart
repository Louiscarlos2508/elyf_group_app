import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/stock_transfer.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/cylinder.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/core/auth/providers.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:elyf_groupe_app/features/administration/application/providers.dart';
import 'package:elyf_groupe_app/core/offline/offline_repository.dart' show LocalIdGenerator;

class StockTransferDialog extends ConsumerStatefulWidget {
  const StockTransferDialog({
    super.key,
    required this.fromEnterpriseId,
    this.initialToEnterpriseId,
  });

  final String fromEnterpriseId;
  final String? initialToEnterpriseId;

  @override
  ConsumerState<StockTransferDialog> createState() => _StockTransferDialogState();
}

class _StockTransferDialogState extends ConsumerState<StockTransferDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  Enterprise? _selectedDestEnterprise;
  final _notesController = TextEditingController();
  
  // Storage for quantities and statuses: key is cylinder.id
  final Map<String, int> _quantities = {};
  final Map<String, CylinderStatus> _statuses = {};

  @override
  void initState() {
    super.initState();
    // Pre-select target if provided
    if (widget.initialToEnterpriseId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final repo = ref.read(enterpriseRepositoryProvider);
          final target = await repo.getEnterpriseById(widget.initialToEnterpriseId!);
          if (target != null && mounted) {
            setState(() => _selectedDestEnterprise = target);
          }
        } catch (e) {
          // Fallback to searching in accessible list if repo fetch fails
          final enterprises = await ref.read(userAccessibleEnterprisesProvider.future);
          final initialTarget = enterprises.where((e) => e.id == widget.initialToEnterpriseId).firstOrNull;
          if (initialTarget != null && mounted) {
            setState(() => _selectedDestEnterprise = initialTarget);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _updateQuantity(String cylinderId, int delta) {
    setState(() {
      final current = _quantities[cylinderId] ?? 0;
      final newValue = current + delta;
      if (newValue >= 0) {
        _quantities[cylinderId] = newValue;
      }
    });
  }

  void _setStatus(String cylinderId, CylinderStatus status) {
    setState(() {
      _statuses[cylinderId] = status;
    });
  }

  Future<void> _submit() async {
    if (_selectedDestEnterprise == null) {
      NotificationService.showError(context, 'Veuillez sélectionner une destination');
      return;
    }
    // Build items list from maps
    final cylinders = ref.read(cylindersProvider).value ?? [];
    final List<StockTransferItem> transferItems = [];
    
    for (final cylinder in cylinders) {
      final qty = _quantities[cylinder.id] ?? 0;
      if (qty > 0) {
        transferItems.add(StockTransferItem(
          weight: cylinder.weight,
          status: _statuses[cylinder.id] ?? CylinderStatus.full,
          quantity: qty,
        ));
      }
    }

    if (transferItems.isEmpty) {
      NotificationService.showError(context, 'Veuillez saisir au moins une quantité');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = ref.read(authControllerProvider);
      final userId = auth.currentUser?.id ?? '';

      final transfer = StockTransfer(
        id: LocalIdGenerator.generate(),
        fromEnterpriseId: widget.fromEnterpriseId,
        toEnterpriseId: _selectedDestEnterprise!.id,
        items: transferItems,
        status: StockTransferStatus.pending,
        createdBy: userId,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(stockTransferControllerProvider).initiateTransfer(transfer);

      if (!mounted) return;
      ref.invalidate(stockTransfersProvider(widget.fromEnterpriseId));
      Navigator.of(context).pop();
      NotificationService.showSuccess(context, 'Transfert initié avec succès');
    } catch (e) {
      if (!mounted) return;
      NotificationService.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accessibleEnterprisesAsync = ref.watch(userAccessibleEnterprisesProvider);
    final cylindersAsync = ref.watch(cylindersProvider);
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nouveau Transfert de Stock',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Destination Selection
                        accessibleEnterprisesAsync.when(
                          data: (enterprises) {
                            final List<Enterprise> destOptions = enterprises
                                .where((e) => e.id != widget.fromEnterpriseId)
                                .toList();
                            
                            // CRITICAL: Ensure _selectedDestEnterprise is in the list
                            if (_selectedDestEnterprise != null && 
                                !destOptions.any((e) => e.id == _selectedDestEnterprise!.id)) {
                              destOptions.insert(0, _selectedDestEnterprise!);
                            }

                            final isLocked = widget.initialToEnterpriseId != null;
                            return DropdownButtonFormField<Enterprise>(
                              value: _selectedDestEnterprise,
                              decoration: InputDecoration(
                                labelText: 'Enterprise de destination *',
                                prefixIcon: const Icon(Icons.business),
                                border: const OutlineInputBorder(),
                                filled: isLocked,
                                fillColor: isLocked ? theme.colorScheme.surfaceContainerHighest : null,
                              ),
                              items: destOptions.map((e) {
                                return DropdownMenuItem(
                                  value: e,
                                  child: Text(e.name),
                                );
                              }).toList(),
                              onChanged: isLocked ? null : (value) => setState(() => _selectedDestEnterprise = value),
                              validator: (value) => value == null ? 'Obligatoire' : null,
                            );
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (e, _) => Text('Erreur: $e'),
                        ),
                        const SizedBox(height: 24),

                        // Items Section
                        Text(
                          'Contenu du transfert',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        cylindersAsync.when(
                          data: (cylinders) {
                            if (cylinders.isEmpty) {
                              return const Center(child: Text('Aucun type de bouteille trouvé'));
                            }
                            return Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: theme.dividerColor.withAlpha(50)),
                              ),
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: cylinders.length,
                                separatorBuilder: (_, __) => Divider(height: 1, color: theme.dividerColor.withAlpha(50)),
                                itemBuilder: (context, index) {
                                  final cylinder = cylinders[index];
                                  final quantity = _quantities[cylinder.id] ?? 0;
                                  final status = _statuses[cylinder.id] ?? CylinderStatus.full;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        // Weight & Label
                                        Expanded(
                                          flex: 2,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${cylinder.weight}kg',
                                                style: theme.textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                cylinder.label ?? 'Standard',
                                                style: theme.textTheme.labelSmall?.copyWith(
                                                  color: theme.colorScheme.onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        // Status Toggle (Simplified)
                                        Container(
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.surface,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: theme.dividerColor.withAlpha(100)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              _StatusToggleButton(
                                                label: 'Pleine',
                                                isSelected: status == CylinderStatus.full,
                                                onTap: () => _setStatus(cylinder.id, CylinderStatus.full),
                                              ),
                                              Container(width: 1, height: 20, color: theme.dividerColor.withAlpha(100)),
                                              _StatusToggleButton(
                                                label: 'Vide',
                                                isSelected: status == CylinderStatus.emptyAtStore,
                                                onTap: () => _setStatus(cylinder.id, CylinderStatus.emptyAtStore),
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        const SizedBox(width: 16),
                                        
                                        // Quantity Controls
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _QtyBtn(
                                              icon: Icons.remove,
                                              onPressed: quantity > 0 ? () => _updateQuantity(cylinder.id, -1) : null,
                                            ),
                                            SizedBox(
                                              width: 50,
                                              child: TextFormField(
                                                initialValue: quantity.toString(),
                                                keyboardType: TextInputType.number,
                                                textAlign: TextAlign.center,
                                                style: theme.textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: quantity > 0 ? theme.colorScheme.primary : theme.disabledColor,
                                                ),
                                                decoration: const InputDecoration(
                                                  isDense: true,
                                                  contentPadding: EdgeInsets.zero,
                                                  border: InputBorder.none,
                                                ),
                                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                onChanged: (val) {
                                                  final newQty = int.tryParse(val) ?? 0;
                                                  setState(() {
                                                    _quantities[cylinder.id] = newQty;
                                                  });
                                                },
                                              ),
                                            ),
                                            _QtyBtn(
                                              icon: Icons.add,
                                              onPressed: () => _updateQuantity(cylinder.id, 1),
                                              isPrimary: true,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Text('Erreur cylinders: $e'),
                        ),
                        const SizedBox(height: 24),

                        // Notes
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'Notes (ex: Plaque immatriculation chauffeur)',
                            border: OutlineInputBorder(),
                            helperText: 'En option',
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElyfButton(
                      onPressed: () => Navigator.of(context).pop(),
                      variant: ElyfButtonVariant.outlined,
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElyfButton(
                      onPressed: _isLoading ? null : _submit,
                      isLoading: _isLoading,
                      icon: Icons.send,
                      child: const Text('Transférer'),
                    ),
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

class _StatusToggleButton extends StatelessWidget {
  const _StatusToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      onPressed: onPressed,
      icon: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isPrimary 
              ? theme.colorScheme.primary.withAlpha(onPressed != null ? 255 : 50) 
              : theme.colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: isPrimary && onPressed != null
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.all(8),
    );
  }
}
