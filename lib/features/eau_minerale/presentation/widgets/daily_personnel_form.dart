import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/daily_worker.dart';
import '../../domain/entities/production_day.dart';
import '../../domain/entities/production_session.dart';
import 'daily_worker_form_dialog.dart';

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
  final _packsController = TextEditingController();
  final _emballagesController = TextEditingController();

  final Set<String> _selectedWorkerIds = {};
  int _nombrePersonnes = 0;
  int _packsProduits = 0;
  int _emballagesUtilises = 0;
  List<DailyWorker> _workers = [];


  @override
  void initState() {
    super.initState();
    if (widget.existingDay != null) {
      _selectedWorkerIds.addAll(widget.existingDay!.personnelIds);
      _nombrePersonnes = widget.existingDay!.nombrePersonnes;
      _notesController.text = widget.existingDay!.notes ?? '';
      _packsProduits = widget.existingDay!.packsProduits;
      _emballagesUtilises = widget.existingDay!.emballagesUtilises;
      if (_packsProduits > 0) {
        _packsController.text = _packsProduits.toString();
      }
      if (_emballagesUtilises > 0) {
        _emballagesController.text = _emballagesUtilises.toString();
      }
    }
    _updateNombrePersonnes();
    
    // Auto-suggestion des emballages
    _packsController.addListener(_updatePackagingSuggestion);
  }

  void _updatePackagingSuggestion() {
    final packsStr = _packsController.text;
    final emballagesStr = _emballagesController.text;
    
    if (emballagesStr.isEmpty || emballagesStr == _previousPacksValue) {
       _emballagesController.text = packsStr;
    }
    _previousPacksValue = packsStr;
  }

  String _previousPacksValue = '';

  @override
  void dispose() {
    _packsController.removeListener(_updatePackagingSuggestion);
    _notesController.dispose();
    _packsController.dispose();
    _emballagesController.dispose();
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
      NotificationService.showWarning(
        context,
        'Sélectionnez au moins une personne',
      );
      return;
    }

    final packs = int.tryParse(_packsController.text.trim());
    final emballages = int.tryParse(_emballagesController.text.trim());

    if (packs == null || packs < 0) {
      NotificationService.showInfo(
        context,
        'Le nombre de packs produits doit être un entier positif',
      );
      return;
    }

    if (emballages == null || emballages < 0) {
      NotificationService.showInfo(
        context,
        'Le nombre d\'emballages utilisés doit être un entier positif',
      );
      return;
    }

    _packsProduits = packs;
    _emballagesUtilises = emballages;

    final totalReel = _coutTotalFromWorkers();
    final salaireMoyen = _salaireMoyenFromWorkers();
    final n = _selectedWorkerIds.length;

    final productionDay = ProductionDay(
      id:
          widget.existingDay?.id ??
          'day-${DateTime.now().millisecondsSinceEpoch}',
      enterpriseId: widget.session.enterpriseId,
      productionId: widget.session.id,
      date: widget.date,
      personnelIds: _selectedWorkerIds.toList(),
      nombrePersonnes: n,
      salaireJournalierParPersonne: salaireMoyen,
      coutTotalPersonnelStored: totalReel > 0 ? totalReel : null,
      packsProduits: _packsProduits,
      emballagesUtilises: _emballagesUtilises,
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
            // Header Section
            ElyfCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 24,
              backgroundColor: colors.primary.withValues(alpha: 0.03),
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

            // Workers Management
            ElyfCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 24,
              backgroundColor: colors.surfaceContainerLow.withValues(alpha: 0.5),
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

            // Production Details
            ElyfCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 24,
              backgroundColor: colors.surfaceContainerLow.withValues(alpha: 0.5),
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
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _packsController,
                          decoration: _buildInputDecoration(
                            label: 'Packs produits',
                            icon: Icons.inventory_2_rounded,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) => v?.trim().isEmpty ?? true ? 'Requis' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPackagingStockField(theme, colors),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Summary Section
            ElyfCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 24,
              backgroundColor: colors.secondary.withValues(alpha: 0.05),
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

            // Notes
            ElyfCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 24,
              backgroundColor: colors.surfaceContainerLow.withValues(alpha: 0.3),
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

  Widget _buildPackagingStockField(ThemeData theme, ColorScheme colors) {
    return FutureBuilder<int>(
      future: ref.read(packagingStockControllerProvider).fetchByType('Emballage').then((s) => s?.quantity ?? 0),
      builder: (context, snapshot) {
        final stock = snapshot.data ?? 0;
        return TextFormField(
          controller: _emballagesController,
          decoration: _buildInputDecoration(
            label: 'Emballages (unités/sachets)',
            icon: Icons.layers_rounded,
            hintText: 'Stock: $stock',
          ),
          keyboardType: TextInputType.number,
          validator: (v) {
            if (v == null || v.isEmpty) return null;
            final val = int.tryParse(v);
            if (val != null && val > stock) return 'Stock insuffisant';
            return null;
          },
        );
      },
    );
  }

  Widget _buildSummaryRow(ThemeData theme, ColorScheme colors, {required IconData icon, required String label, required String value, required Color badgeColor}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: badgeColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(12)),
          child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({required String label, required IconData icon, String? hintText}) {
    final colors = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: Icon(icon, size: 20, color: colors.primary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colors.outline.withValues(alpha: 0.1))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colors.outline.withValues(alpha: 0.1))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colors.primary, width: 2)),
      filled: true,
      fillColor: colors.surfaceContainerLow.withValues(alpha: 0.3),
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
