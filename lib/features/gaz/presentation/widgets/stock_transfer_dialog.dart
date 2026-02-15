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
import 'package:elyf_groupe_app/core/offline/offline_repository.dart' show LocalIdGenerator;

class StockTransferDialog extends ConsumerStatefulWidget {
  const StockTransferDialog({
    super.key,
    required this.fromEnterpriseId,
  });

  final String fromEnterpriseId;

  @override
  ConsumerState<StockTransferDialog> createState() => _StockTransferDialogState();
}

class _StockTransferDialogState extends ConsumerState<StockTransferDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  Enterprise? _selectedDestEnterprise;
  final _notesController = TextEditingController();
  final List<StockTransferItem> _items = [];

  // Temporary state for the "Add Item" section
  Cylinder? _tempSelectedCylinder;
  CylinderStatus _tempSelectedStatus = CylinderStatus.full;
  final _tempQuantityController = TextEditingController(text: '1');

  @override
  void dispose() {
    _notesController.dispose();
    _tempQuantityController.dispose();
    super.dispose();
  }

  void _addItem() {
    if (_tempSelectedCylinder == null) return;
    final quantity = int.tryParse(_tempQuantityController.text) ?? 0;
    if (quantity <= 0) return;

    setState(() {
      _items.add(StockTransferItem(
        weight: _tempSelectedCylinder!.weight,
        status: _tempSelectedStatus,
        quantity: quantity,
      ));
      _tempSelectedCylinder = null;
      _tempQuantityController.text = '1';
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (_selectedDestEnterprise == null) {
      NotificationService.showError(context, 'Veuillez sélectionner une destination');
      return;
    }
    if (_items.isEmpty) {
      NotificationService.showError(context, 'Veuillez ajouter au moins une bouteille');
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
        items: _items,
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
                            final destOptions = enterprises
                                .where((e) => e.id != widget.fromEnterpriseId)
                                .toList();
                            return DropdownButtonFormField<Enterprise>(
                              initialValue: _selectedDestEnterprise,
                              decoration: const InputDecoration(
                                labelText: 'Enterprise de destination *',
                                prefixIcon: Icon(Icons.business),
                                border: OutlineInputBorder(),
                              ),
                              items: destOptions.map((e) {
                                return DropdownMenuItem(
                                  value: e,
                                  child: Text(e.name),
                                );
                              }).toList(),
                              onChanged: (value) => setState(() => _selectedDestEnterprise = value),
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
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Add Item Form
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(76),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: cylindersAsync.when(
                                      data: (cylinders) {
                                        return DropdownButtonFormField<Cylinder>(
                                          initialValue: _tempSelectedCylinder,
                                          decoration: const InputDecoration(
                                            labelText: 'Bouteille',
                                            border: OutlineInputBorder(),
                                          ),
                                          items: cylinders.map((c) {
                                            return DropdownMenuItem(
                                              value: c,
                                              child: Text('${c.weight}kg'),
                                            );
                                          }).toList(),
                                          onChanged: (value) => setState(() => _tempSelectedCylinder = value),
                                        );
                                      },
                                      loading: () => const CircularProgressIndicator(),
                                      error: (_, __) => const Icon(Icons.error),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: DropdownButtonFormField<CylinderStatus>(
                                      initialValue: _tempSelectedStatus,
                                      decoration: const InputDecoration(
                                        labelText: 'Statut',
                                        border: OutlineInputBorder(),
                                      ),
                                      items: CylinderStatus.values.map((s) {
                                        return DropdownMenuItem(
                                          value: s,
                                          child: Text(s.label),
                                        );
                                      }).toList(),
                                      onChanged: (value) => setState(() => _tempSelectedStatus = value!),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 1,
                                    child: TextFormField(
                                      controller: _tempQuantityController,
                                      decoration: const InputDecoration(
                                        labelText: 'Qté',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton.filledTonal(
                                    onPressed: _addItem,
                                    icon: const Icon(Icons.add),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Items List
                        if (_items.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Text('Aucun article ajouté'),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              return ListTile(
                                tileColor: Theme.of(context).colorScheme.surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Theme.of(context).dividerColor),
                                ),
                                title: Text('${item.weight}kg (${item.status.label})'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'x${item.quantity}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () => _removeItem(index),
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    ),
                                  ],
                                ),
                              );
                            },
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
                      child: const Text('Initier'),
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
