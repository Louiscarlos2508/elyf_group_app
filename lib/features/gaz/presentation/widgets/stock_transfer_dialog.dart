import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/stock_transfer.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/cylinder.dart';
import 'package:elyf_groupe_app/features/gaz/domain/services/gaz_calculation_service.dart';
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
  final Map<String, TextEditingController> _controllers = {};

  TextEditingController _getController(String cylinderId) {
    return _controllers.putIfAbsent(
      cylinderId,
      () => TextEditingController(text: (_quantities[cylinderId] ?? 0).toString()),
    );
  }

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
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateQuantity(String cylinderId, int delta) {
    setState(() {
      final current = _quantities[cylinderId] ?? 0;
      final newValue = current + delta;
      if (newValue >= 0) {
        _quantities[cylinderId] = newValue;
        _controllers[cylinderId]?.text = newValue.toString();
      }
    });
  }

  void _setStatus(String cylinderId, CylinderStatus status) {
    setState(() {
      _statuses[cylinderId] = status;
      
      // Re-calculate maxAvailable for the new status and clamp the existing quantity
      final cylinders = ref.read(cylindersProvider).value ?? [];
      final cylinder = cylinders.firstWhere((c) => c.id == cylinderId, orElse: () => cylinders.first);
      final stocks = ref.read(cylinderStocksProvider((
        enterpriseId: widget.fromEnterpriseId,
        status: null,
        siteId: null,
      ))).value ?? [];
      final settings = ref.read(gazSettingsProvider((
        enterpriseId: widget.fromEnterpriseId,
        moduleId: 'gaz',
      ))).value;

      final metrics = GazCalculationService.calculateStockMetrics(
        stocks: stocks,
        pointsOfSale: [],
        cylinders: cylinders,
        settings: settings,
        targetEnterpriseId: widget.fromEnterpriseId,
      );

      int maxAvailable = 0;
      if (status == CylinderStatus.full) {
        maxAvailable = metrics.fullByWeight[cylinder.weight] ?? 0;
      } else {
        maxAvailable = metrics.emptyByWeight[cylinder.weight] ?? 0;
      }

      final current = _quantities[cylinderId] ?? 0;
      if (current > maxAvailable) {
        _quantities[cylinderId] = maxAvailable.clamp(0, 9999);
        _controllers[cylinderId]?.text = _quantities[cylinderId].toString();
      }
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
    // We use allEnterprisesStreamProvider instead of userAccessibleEnterprisesProvider
    // to allow transferring to any node in the gaz network.
    final accessibleEnterprisesAsync = ref.watch(allEnterprisesStreamProvider);
    final cylindersAsync = ref.watch(cylindersProvider);
    
    // Watch source stocks for availability constraints
    final sourceStocksAsync = ref.watch(cylinderStocksProvider((
      enterpriseId: widget.fromEnterpriseId,
      status: null,
      siteId: null,
    )));
    
    final sourceSettingsAsync = ref.watch(gazSettingsProvider((
      enterpriseId: widget.fromEnterpriseId,
      moduleId: 'gaz',
    )));
    
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
                            // Filter destinations: exclude source, must be same module
                            final List<Enterprise> destOptions = enterprises
                                .where((e) => e.id != widget.fromEnterpriseId)
                                .where((e) => e.type.module == EnterpriseModule.gaz)
                                .toList();
                            
                            // Sort by name
                            destOptions.sort((a, b) => a.name.compareTo(b.name));
                            
                            // CRITICAL: Ensure _selectedDestEnterprise is in the list
                            if (_selectedDestEnterprise != null && 
                                !destOptions.any((e) => e.id == _selectedDestEnterprise!.id)) {
                              destOptions.insert(0, _selectedDestEnterprise!);
                            }

                            final isLocked = widget.initialToEnterpriseId != null;
                            return DropdownButtonFormField<Enterprise>(
                              key: ValueKey(_selectedDestEnterprise?.id), // Use key to force refresh if needed
                              initialValue: _selectedDestEnterprise,
                              decoration: InputDecoration(
                                labelText: 'Destination (Point de Vente / Dépôt) *',
                                prefixIcon: const Icon(Icons.location_on_outlined),
                                border: const OutlineInputBorder(),
                                filled: isLocked,
                                fillColor: isLocked ? theme.colorScheme.surfaceContainerHighest : null,
                                helperText: 'Choisissez le destinataire du stock',
                              ),
                              items: destOptions.map((e) {
                                final isSubEntity = e.parentEnterpriseId != null;
                                return DropdownMenuItem(
                                  value: e,
                                  child: Row(
                                    children: [
                                      Icon(e.type.icon, size: 18, color: theme.colorScheme.primary),
                                      const SizedBox(width: 8),
                                      Text(
                                        e.name,
                                        style: TextStyle(
                                          fontWeight: isSubEntity ? FontWeight.normal : FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: isLocked ? null : (value) => setState(() => _selectedDestEnterprise = value),
                              validator: (value) => value == null ? 'Obligatoire' : null,
                            );
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (e, _) => Text('Erreur chargement destinations: $e'),
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
                                  
                                  // Standardized availability calculation using Service
                                  final stocks = sourceStocksAsync.value ?? [];
                                  final settings = sourceSettingsAsync.value;

                                  final metrics = GazCalculationService.calculateStockMetrics(
                                    stocks: stocks,
                                    pointsOfSale: [],
                                    cylinders: cylinders,
                                    settings: settings,
                                    targetEnterpriseId: widget.fromEnterpriseId,
                                  );
                                  
                                  final maxAvailable = status == CylinderStatus.full 
                                    ? (metrics.fullByWeight[cylinder.weight] ?? 0)
                                    : (metrics.emptyByWeight[cylinder.weight] ?? 0);

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
                                                'Dispo: $maxAvailable',
                                                style: theme.textTheme.labelSmall?.copyWith(
                                                  color: maxAvailable > 0 ? Colors.green : Colors.red,
                                                  fontWeight: FontWeight.bold,
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
                                                controller: _getController(cylinder.id),
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
                                                  final enteredQty = int.tryParse(val) ?? 0;
                                                  final newQty = enteredQty.clamp(0, maxAvailable).toInt();
                                                  
                                                  setState(() {
                                                    _quantities[cylinder.id] = newQty;
                                                  });
                                                  
                                                  if (newQty != enteredQty) {
                                                    _controllers[cylinder.id]?.text = newQty.toString();
                                                    _controllers[cylinder.id]?.selection = TextSelection.fromPosition(
                                                      TextPosition(offset: newQty.toString().length),
                                                    );
                                                  }
                                                },
                                              ),
                                            ),
                                              _QtyBtn(
                                                icon: Icons.add,
                                                onPressed: quantity < maxAvailable ? () => _updateQuantity(cylinder.id, 1) : null,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
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
