import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/daily_worker.dart';
import '../../domain/entities/production_day.dart';
import '../../domain/entities/production_session.dart';
import 'daily_worker_form_dialog.dart';
import '../../domain/entities/material_consumption.dart';
import '../../domain/entities/product.dart';

/// Formulaire pour enregistrer le personnel journalier pour un jour de production.
class DailyPersonnelForm extends ConsumerStatefulWidget {
  const DailyPersonnelForm({
    super.key,
    required this.session,
    required this.date,
    this.existingDay,
    required this.onSaved,
  });

  final ProductionSession session;
  final DateTime date;
  final ProductionDay? existingDay;
  final ValueChanged<ProductionDay> onSaved;

  @override
  ConsumerState<DailyPersonnelForm> createState() => _DailyPersonnelFormState();
}

class _DailyPersonnelFormState extends ConsumerState<DailyPersonnelForm> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _emballagesController = TextEditingController();
  final _directProductionController = TextEditingController();
  final _directMaterialController = TextEditingController();
  Product? _uniqueFinishedGood;
  Product? _uniqueRawMaterial;

  final Set<String> _selectedWorkerIds = {};
  int _nombrePersonnes = 0;
  List<MaterialConsumption> _consumptions = [];
  List<MaterialConsumption> _producedItems = [];
  List<DailyWorker> _workers = [];
  bool _isMaterialManuallyModified = false;
  final FocusNode _materialFocusNode = FocusNode();


  @override
  void initState() {
    super.initState();
    if (widget.existingDay != null) {
      _selectedWorkerIds.addAll(widget.existingDay!.personnelIds);
      _nombrePersonnes = widget.existingDay!.nombrePersonnes;
      _notesController.text = widget.existingDay!.notes ?? '';
      _consumptions = List.from(widget.existingDay!.consumptions);
      _producedItems = List.from(widget.existingDay!.producedItems);
      
      // Initialiser les controllers directs si possible
      if (_producedItems.isNotEmpty) {
        _directProductionController.text = _producedItems.first.quantity.toInt().toString();
      }
      if (_consumptions.isNotEmpty) {
        _directMaterialController.text = _consumptions.first.quantity.toString();
      }
    }
    _updateNombrePersonnes();

    // Synchronisation bidirectionnelle réactive
    _directProductionController.addListener(() {
      if (_uniqueFinishedGood != null && _directProductionController.text.isNotEmpty) {
        final qtyStr = _directProductionController.text.replaceFirst(',', '.');
        final qty = double.tryParse(qtyStr) ?? 0;
        _updateProducedItemDirectly(_uniqueFinishedGood!, qty);
        
        // Sync auto avec la matière si l'utilisateur ne l'a pas encore modifiée manuellement
        if (_uniqueRawMaterial != null && !_isMaterialManuallyModified) {
           _directMaterialController.text = _directProductionController.text;
        }
      }
    });

    _directMaterialController.addListener(() {
      if (_uniqueRawMaterial != null) {
        // Détecter si la modification vient d'une saisie manuelle (champ focusé)
        if (_materialFocusNode.hasFocus && _directMaterialController.text.isNotEmpty) {
           _isMaterialManuallyModified = true;
        }

        if (_directMaterialController.text.isNotEmpty) {
          final qtyStr = _directMaterialController.text.replaceFirst(',', '.');
          final qty = double.tryParse(qtyStr) ?? 0;
          _updateMaterialDirectly(_uniqueRawMaterial!, qty);
        }
      }
    });
  }

  void _updateProducedItemDirectly(Product p, double qty) {
     final item = MaterialConsumption(
      productId: p.id,
      productName: p.name,
      quantity: qty,
      unit: p.unit,
      unitsPerLot: p.unitsPerLot,
    );
    setState(() {
      final index = _producedItems.indexWhere((c) => c.productId == p.id);
      if (index >= 0) {
        _producedItems[index] = item;
      } else {
        _producedItems.add(item);
      }
    });
  }

  void _updateMaterialDirectly(Product p, double qty) {
     final item = MaterialConsumption(
      productId: p.id,
      productName: p.name,
      quantity: qty,
      unit: p.unit,
      unitsPerLot: p.unitsPerLot,
    );
     setState(() {
      final index = _consumptions.indexWhere((c) => c.productId == p.id);
      if (index >= 0) {
        _consumptions[index] = item;
      } else {
        _consumptions.add(item);
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _emballagesController.dispose();
    _directProductionController.dispose();
    _directMaterialController.dispose();
    _materialFocusNode.dispose();
    super.dispose();
  }

  int _coutTotalFromWorkers() {
    if (_selectedWorkerIds.isEmpty || _workers.isEmpty) return 0;
    return _workers
        .where((w) => _selectedWorkerIds.contains(w.id))
        .fold<int>(0, (s, w) => s + w.salaireJournalier);
  }

  int _salaireMoyenFromWorkers() {
    final n = _selectedWorkerIds.length;
    if (n == 0) return 0;
    final total = _coutTotalFromWorkers();
    return (total / n).round();
  }

  void _updateNombrePersonnes() {
    setState(() {
      _nombrePersonnes = _selectedWorkerIds.length;
    });
  }

  void _toggleWorker(String workerId) {
    setState(() {
      if (_selectedWorkerIds.contains(workerId)) {
        _selectedWorkerIds.remove(workerId);
      } else {
        _selectedWorkerIds.add(workerId);
      }
      _updateNombrePersonnes();
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedWorkerIds.isEmpty) {
      NotificationService.showWarning(context, 'Sélectionnez au moins une personne');
      return;
    }

    final totalReel = _coutTotalFromWorkers();
    final salaireMoyen = _salaireMoyenFromWorkers();
    final n = _selectedWorkerIds.length;

    final productionDay = ProductionDay(
      id: widget.existingDay?.id ?? 'day-${DateTime.now().millisecondsSinceEpoch}',
      enterpriseId: widget.session.enterpriseId,
      productionId: widget.session.id,
      date: widget.date,
      personnelIds: _selectedWorkerIds.toList(),
      nombrePersonnes: n,
      salaireJournalierParPersonne: salaireMoyen,
      coutTotalPersonnelStored: totalReel > 0 ? totalReel : null,
      packsProduits: _producedItems.fold<double>(0.0, (s, i) => s + i.quantity).toInt(),
      emballagesUtilises: _consumptions.fold<double>(0.0, (s, i) => s + i.quantity).toInt(),
      consumptions: _consumptions,
      producedItems: _producedItems,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      createdAt: widget.existingDay?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    widget.onSaved(productionDay);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElyfCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 24,
              backgroundColor: colors.primary.withValues(alpha: 0.15),
              borderColor: colors.primary.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.badge_rounded, color: colors.primary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personnel Journalier',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: colors.onSurface),
                        ),
                        Text(
                          DateFormatter.formatLongDate(widget.date),
                          style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            ElyfCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 24,
              backgroundColor: colors.surfaceContainerLow,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.groups_rounded, size: 18, color: colors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Ouvriers Disponibles',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: colors.primary),
                      ),
                      const Spacer(),
                      IconButton.filledTonal(
                        onPressed: () async {
                          final result = await showDialog<DailyWorker>(
                            context: context,
                            builder: (context) => const DailyWorkerFormDialog(),
                          );
                          if (result != null && mounted) ref.invalidate(allDailyWorkersProvider);
                        },
                        icon: const Icon(Icons.add_rounded, size: 18),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ref.watch(allDailyWorkersProvider).when(
                    data: (workers) {
                      if (workers.isEmpty) return _buildEmptyWorkersView(theme, colors);
                      _workers = workers;
                      return Column(
                        children: workers.map((worker) => _buildWorkerItem(theme, colors, worker)).toList(),
                      );
                    },
                    loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                    error: (error, stack) => _buildErrorView(theme, colors),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            ref.watch(productsProvider).when(
              data: (allProducts) {
                final finishedGoods = allProducts.where((p) => p.isFinishedGood).toList();
                
                return ref.watch(rawMaterialsProvider).when(
                  data: (rawMaterials) {
                    final filteredMaterials = rawMaterials.where((p) => !p.name.toLowerCase().contains('bobine')).toList();
                    _uniqueFinishedGood = finishedGoods.length == 1 ? finishedGoods.first : null;
                    _uniqueRawMaterial = filteredMaterials.length == 1 ? filteredMaterials.first : null;

                    return Column(
                      children: [
                        ElyfCard(
                          padding: const EdgeInsets.all(20),
                          borderRadius: 24,
                          backgroundColor: colors.surfaceContainerLow,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.analytics_rounded, size: 18, color: colors.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Production du Jour',
                                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: colors.primary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              if (_uniqueFinishedGood != null)
                                _buildDirectEntryField(
                                  theme, 
                                  colors, 
                                  label: 'Quantité Produite (${_uniqueFinishedGood!.name})',
                                  controller: _directProductionController,
                                  unit: _uniqueFinishedGood!.unit,
                                )
                              else
                                _buildProductionSection(theme, colors),
                              
                              const SizedBox(height: 24),
                              
                              if (_uniqueRawMaterial != null)
                                _buildDirectEntryField(
                                  theme, 
                                  colors, 
                                  label: 'Matière Consommée (${_uniqueRawMaterial!.name})',
                                  controller: _directMaterialController,
                                  unit: _uniqueRawMaterial!.unit,
                                  focusNode: _materialFocusNode,
                                )
                              else
                                _buildMaterialsSection(theme, colors),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),

            ElyfCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 24,
              backgroundColor: colors.surfaceContainerLow,
              borderColor: colors.secondary.withValues(alpha: 0.1),
              child: Column(
                children: [
                  _buildSummaryRow(
                    theme, 
                    colors, 
                    icon: Icons.people_alt_rounded, 
                    label: 'Personnel Présent', 
                    value: '$_nombrePersonnes',
                    badgeColor: colors.primary,
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    theme, 
                    colors, 
                    icon: Icons.payments_rounded, 
                    label: 'Coût Main d\'œuvre', 
                    value: '${_coutTotalFromWorkers()} CFA',
                    badgeColor: colors.secondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            ElyfCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 24,
              backgroundColor: colors.surfaceContainerLow,
              child: TextFormField(
                controller: _notesController,
                decoration: _buildInputDecoration(
                  label: 'Notes / Observations (Optionnel)',
                  icon: Icons.note_alt_rounded,
                ),
                maxLines: 2,
              ),
            ),
            const SizedBox(height: 32),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    ThemeData theme, 
    ColorScheme colors, {
    required IconData icon, 
    required String label, 
    required String value,
    required Color badgeColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: badgeColor),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: colors.onSurface),
        ),
      ],
    );
  }

  Widget _buildWorkerItem(ThemeData theme, ColorScheme colors, DailyWorker worker) {
     final isSelected = _selectedWorkerIds.contains(worker.id);
     return Padding(
       padding: const EdgeInsets.only(bottom: 8),
       child: InkWell(
         onTap: () => _toggleWorker(worker.id),
         borderRadius: BorderRadius.circular(16),
         child: AnimatedContainer(
           duration: const Duration(milliseconds: 200),
           padding: const EdgeInsets.all(12),
           decoration: BoxDecoration(
             color: isSelected ? colors.primary.withValues(alpha: 0.1) : colors.surface,
             borderRadius: BorderRadius.circular(16),
             border: Border.all(
               color: isSelected ? colors.primary : colors.outline.withValues(alpha: 0.1),
               width: isSelected ? 2 : 1,
             ),
           ),
           child: Row(
             children: [
               CircleAvatar(
                 backgroundColor: isSelected ? colors.primary : colors.primaryContainer.withValues(alpha: 0.5),
                 foregroundColor: isSelected ? colors.onPrimary : colors.primary,
                 child: Text(worker.name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
               ),
               const SizedBox(width: 16),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(worker.name, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                     Text('${worker.salaireJournalier} CFA/jour', style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                   ],
                 ),
               ),
               Checkbox(
                 value: isSelected,
                 onChanged: (_) => _toggleWorker(worker.id),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
               ),
             ],
           ),
         ),
       ),
     );
  }

  Widget _buildEmptyWorkersView(ThemeData theme, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: colors.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
           Icon(Icons.person_off_rounded, size: 48, color: colors.onSurfaceVariant.withValues(alpha: 0.5)),
           const SizedBox(height: 16),
           Text('Aucun ouvrier enregistré', style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }

  Widget _buildErrorView(ThemeData theme, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.errorContainer.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
      child: Row(children: [Icon(Icons.error_outline, color: colors.error), const SizedBox(width: 12), Text('Erreur de chargement', style: TextStyle(color: colors.error))]),
    );
  }

  Widget _buildProductionSection(ThemeData theme, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.inventory_2_rounded, size: 18, color: colors.primary),
            const SizedBox(width: 8),
            Text(
              'Production Produits Finis',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: colors.primary),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _showProductionSelector,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Ajouter'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_producedItems.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Aucune production ajoutée',
                style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: colors.onSurfaceVariant),
              ),
            ),
          )
        else
          ..._producedItems.map((c) => _buildProducedItem(theme, colors, c)),
      ],
    );
  }

  Widget _buildProducedItem(ThemeData theme, ColorScheme colors, MaterialConsumption consumption) {
    return ElyfCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      backgroundColor: colors.primary.withValues(alpha: 0.05),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  consumption.productName,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${consumption.quantity.toInt()} ${consumption.unit}',
                  style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_rounded, color: colors.primary, size: 20),
            onPressed: () => _editProducedItem(consumption),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: colors.error, size: 20),
            onPressed: () => setState(() => _producedItems.remove(consumption)),
          ),
        ],
      ),
    );
  }

  void _editProducedItem(MaterialConsumption c) async {
    final allProducts = await ref.read(productsProvider.future);
    final finishedGoods = allProducts.where((p) => p.isFinishedGood).toList();
    final p = finishedGoods.firstWhere((p) => p.id == c.productId);

    if (!mounted) return;

    final result = await showDialog<MaterialEntryResult>(
      context: context,
      builder: (context) => _MaterialSelectionDialog(
        products: [p],
        title: 'Modifier Production',
        initialQuantity: c.quantity.toInt().toString(),
      ),
    );

    if (result != null) {
      setState(() {
        final index = _producedItems.indexOf(c);
        if (index >= 0) _producedItems[index] = result.mainEntry;
      });
    }
  }

  void _showProductionSelector() async {
    final allProducts = await ref.read(productsProvider.future);
    final finishedGoods = allProducts.where((p) => p.isFinishedGood).toList();
    
    final rawMaterials = await ref.read(rawMaterialsProvider.future);
    final filteredMaterials = rawMaterials.where((p) => !p.name.toLowerCase().contains('bobine')).toList();

    if (!mounted) return;

    final result = await showDialog<MaterialEntryResult>(
      context: context,
      builder: (context) => _MaterialSelectionDialog(
        products: finishedGoods,
        title: 'Ajouter Production',
        showIntegratedConsumption: true,
        availableMaterials: filteredMaterials,
      ),
    );

    if (result != null) {
      setState(() {
        final prodIndex = _producedItems.indexWhere((c) => c.productId == result.mainEntry.productId);
        if (prodIndex >= 0) {
          _producedItems[prodIndex] = result.mainEntry;
        } else {
          _producedItems.add(result.mainEntry);
        }

        if (result.associatedConsumption != null) {
          final consIndex = _consumptions.indexWhere((c) => c.productId == result.associatedConsumption!.productId);
          if (consIndex >= 0) {
            _consumptions[consIndex] = result.associatedConsumption!;
          } else {
            _consumptions.add(result.associatedConsumption!);
          }
        }
      });
    }
  }

  Widget _buildMaterialsSection(ThemeData theme, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.layers_rounded, size: 18, color: colors.primary),
            const SizedBox(width: 8),
            Text(
              'Matières Consommées',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: colors.primary),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _showMaterialSelector,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Ajouter'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_consumptions.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Aucune matière ajoutée',
                style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: colors.onSurfaceVariant),
              ),
            ),
          )
        else
          ..._consumptions.map((c) => _buildMaterialItem(theme, colors, c)),
      ],
    );
  }

  Widget _buildMaterialItem(ThemeData theme, ColorScheme colors, MaterialConsumption consumption) {
    return ElyfCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      backgroundColor: colors.surfaceContainerLow,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  consumption.productName,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${consumption.quantity} ${consumption.unit}',
                  style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_rounded, color: colors.primary, size: 20),
            onPressed: () => _editMaterialItem(consumption),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: colors.error, size: 20),
            onPressed: () => setState(() => _consumptions.remove(consumption)),
          ),
        ],
      ),
    );
  }

  void _editMaterialItem(MaterialConsumption c) async {
    final rawMaterials = await ref.read(rawMaterialsProvider.future);
    final p = rawMaterials.firstWhere((p) => p.id == c.productId);

    if (!mounted) return;

    final result = await showDialog<MaterialEntryResult>(
      context: context,
      builder: (context) => _MaterialSelectionDialog(
        products: [p],
        title: 'Modifier Consommation',
        initialQuantity: c.quantity.toString(),
      ),
    );

    if (result != null) {
      setState(() {
        final index = _consumptions.indexOf(c);
        if (index >= 0) _consumptions[index] = result.mainEntry;
      });
    }
  }

  void _showMaterialSelector() async {
    final rawMaterials = await ref.read(rawMaterialsProvider.future);
    final filteredMaterials = rawMaterials.where((p) => !p.name.toLowerCase().contains('bobine')).toList();
    
    if (!mounted) return;

    final result = await showDialog<MaterialEntryResult>(
      context: context,
      builder: (context) => _MaterialSelectionDialog(
        products: filteredMaterials,
        title: 'Consommation Matière',
      ),
    );

    if (result != null) {
      setState(() {
        final index = _consumptions.indexWhere((c) => c.productId == result.mainEntry.productId);
        if (index >= 0) {
          _consumptions[index] = result.mainEntry;
        } else {
          _consumptions.add(result.mainEntry);
        }
      });
    }
  }

  Widget _buildDirectEntryField(
    ThemeData theme, 
    ColorScheme colors, {
    required String label, 
    required TextEditingController controller,
    required String unit,
    FocusNode? focusNode,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      decoration: _buildInputDecoration(
        label: label,
        icon: Icons.edit_note_rounded,
        suffixText: unit,
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String label, required IconData icon, String? hintText, String? suffixText}) {
    final colors = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      suffixText: suffixText,
      prefixIcon: Icon(icon, size: 20, color: colors.primary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colors.outline.withValues(alpha: 0.1))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colors.outline.withValues(alpha: 0.1))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colors.primary, width: 2)),
      filled: true,
      fillColor: colors.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildSubmitButton() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colors.primary, colors.secondary]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: colors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: ElevatedButton(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text('ENREGISTRER LE PERSONNEL', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
      ),
    );
  }
}

class MaterialEntryResult {
  final MaterialConsumption mainEntry;
  final MaterialConsumption? associatedConsumption;

  MaterialEntryResult({required this.mainEntry, this.associatedConsumption});
}

class _MaterialSelectionDialog extends StatefulWidget {
  const _MaterialSelectionDialog({
    required this.products, 
    this.title = 'Consommation Matière',
    this.initialQuantity,
    this.showIntegratedConsumption = false,
    this.availableMaterials = const [],
  });
  final List<Product> products;
  final String title;
  final String? initialQuantity;
  final bool showIntegratedConsumption;
  final List<Product> availableMaterials;

  @override
  State<_MaterialSelectionDialog> createState() => _MaterialSelectionDialogState();
}

class _MaterialSelectionDialogState extends State<_MaterialSelectionDialog> {
  Product? _selectedProduct;
  Product? _associatedMaterial;
  final _quantityController = TextEditingController();
  bool _syncConsumption = true;

  @override
  void initState() {
    super.initState();
    if (widget.products.length == 1) {
      _selectedProduct = widget.products.first;
    }
    if (widget.availableMaterials.length == 1) {
      _associatedMaterial = widget.availableMaterials.first;
    }
    if (widget.initialQuantity != null) {
      _quantityController.text = widget.initialQuantity!;
    }
    
    // Pour réactiver le bouton au fur et à mesure de la saisie
    _quantityController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    final qtyStr = _quantityController.text.replaceFirst(',', '.');
    final qty = double.tryParse(qtyStr) ?? 0;
    if (qty <= 0 || _selectedProduct == null) return;
    
    final mainEntry = MaterialConsumption(
      productId: _selectedProduct!.id,
      productName: _selectedProduct!.name,
      quantity: qty,
      unit: _selectedProduct!.unit,
      unitsPerLot: _selectedProduct!.unitsPerLot,
    );

    MaterialConsumption? associated;
    if (widget.showIntegratedConsumption && _syncConsumption && _associatedMaterial != null) {
      associated = MaterialConsumption(
        productId: _associatedMaterial!.id,
        productName: _associatedMaterial!.name,
        quantity: qty,
        unit: _associatedMaterial!.unit,
        unitsPerLot: _associatedMaterial!.unitsPerLot,
      );
    }

    Navigator.pop(context, MaterialEntryResult(
      mainEntry: mainEntry,
      associatedConsumption: associated,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<Product>(
              value: _selectedProduct,
              isExpanded: true,
              items: widget.products.map((p) => DropdownMenuItem<Product>(
                value: p,
                child: Text(p.name, overflow: TextOverflow.ellipsis),
              )).toList(),
              onChanged: widget.products.length <= 1 ? null : (p) => setState(() {
                _selectedProduct = p;
              }),
              decoration: const InputDecoration(
                labelText: 'Produit/Matière',
                border: OutlineInputBorder(),
              ),
            ),
            if (_selectedProduct != null) ...[
              const SizedBox(height: 20),
              TextFormField(
                controller: _quantityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _onConfirm(),
                decoration: InputDecoration(
                  labelText: 'Quantité',
                  suffixText: _selectedProduct!.unit,
                  border: const OutlineInputBorder(),
                  helperText: 'Unité: ${_selectedProduct!.unit}',
                ),
                autofocus: true,
              ),
              if (widget.showIntegratedConsumption && _associatedMaterial != null) ...[
                const SizedBox(height: 16),
                ElyfCard(
                  padding: const EdgeInsets.all(12),
                  backgroundColor: colors.primary.withValues(alpha: 0.1),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Consommation liée (${_associatedMaterial!.name})',
                              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Sera égale à la production',
                              style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _syncConsumption,
                        onChanged: (v) => setState(() => _syncConsumption = v),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ANNULER'),
        ),
        ElevatedButton(
          onPressed: _selectedProduct == null || _quantityController.text.isEmpty ? null : _onConfirm,
          child: const Text('ENREGISTRER'),
        ),
      ],
    );
  }
}
