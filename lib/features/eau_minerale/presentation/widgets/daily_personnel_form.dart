import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/daily_worker.dart';
import '../../domain/entities/production_day.dart';
import '../../domain/entities/production_session.dart';
import 'daily_worker_form_dialog.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/notification_service.dart';

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
  String _workersKey = '';

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
  }

  @override
  void dispose() {
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

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Personnel journalier - ${_formatDate(widget.date)}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sélectionnez les personnes présentes pour ce jour de production.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Sélection des ouvriers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Ouvriers disponibles',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IntrinsicWidth(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final result = await showDialog<DailyWorker>(
                        context: context,
                        builder: (context) => const DailyWorkerFormDialog(),
                      );
                      if (result != null && mounted) {
                        // Rafraîchir la liste des ouvriers
                        ref.invalidate(allDailyWorkersProvider);
                      }
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Ajouter'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Récupération des ouvriers depuis le provider
            ref
                .watch(allDailyWorkersProvider)
                .when(
                  data: (workers) {
                    if (workers.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.person_add,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Aucun ouvrier disponible',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Cliquez sur "Ajouter" ci-dessus pour créer un nouvel ouvrier',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }
                    final idsKey = workers.map((w) => w.id).join(',');
                    if (idsKey != _workersKey) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _workers = workers;
                            _workersKey = idsKey;
                          });
                        }
                      });
                    }
                    return Column(
                      children: workers.map((worker) {
                        final isSelected = _selectedWorkerIds.contains(
                          worker.id,
                        );
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: isSelected
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surface,
                          child: CheckboxListTile(
                            title: Text(worker.name),
                            subtitle: Text(
                              '${worker.phone} • ${worker.salaireJournalier} CFA/jour',
                            ),
                            value: isSelected,
                            onChanged: (_) => _toggleWorker(worker.id),
                            secondary: CircleAvatar(
                              child: Text(worker.name[0].toUpperCase()),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, stack) => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Erreur lors du chargement des ouvriers',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

            const SizedBox(height: 24),

            // Production journalière
            Text(
              'Production de la journée',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _packsController,
                    decoration: const InputDecoration(
                      labelText: 'Packs produits (jour)',
                      prefixIcon: Icon(Icons.inventory_2),
                      helperText:
                          'Nombre de packs produits ce jour (obligatoire)',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Obligatoire';
                      }
                      final n = int.tryParse(value.trim());
                      if (n == null || n < 0) {
                        return 'Entier positif requis';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FutureBuilder<int>(
                    future: ref
                        .read(packagingStockControllerProvider)
                        .fetchByType('Emballage')
                        .then((stock) => stock?.quantity ?? 0),
                    builder: (context, snapshot) {
                      final stockDisponible = snapshot.data ?? 0;
                      return TextFormField(
                        controller: _emballagesController,
                        decoration: InputDecoration(
                          labelText: 'Emballages utilisés (jour)',
                          prefixIcon: const Icon(Icons.shopping_bag),
                          helperText:
                              snapshot.connectionState ==
                                  ConnectionState.waiting
                              ? 'Chargement du stock...'
                              : 'Stock disponible: $stockDisponible unité${stockDisponible > 1 ? 's' : ''}',
                          helperMaxLines: 2,
                        ),
                        keyboardType: TextInputType.number,
                        enabled:
                            snapshot.connectionState != ConnectionState.waiting,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return null; // Optionnel
                          }
                          final emballages = int.tryParse(value.trim());
                          if (emballages == null || emballages < 0) {
                            return 'Nombre invalide';
                          }
                          if (emballages > stockDisponible) {
                            return 'Stock insuffisant ($stockDisponible disponible${stockDisponible > 1 ? 's' : ''})';
                          }
                          return null;
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Nombre de personnes et coût (salaire issu des ouvriers)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nombre de personnes sélectionnées',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$_nombrePersonnes',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                prefixIcon: Icon(Icons.note),
                helperText: 'Optionnel',
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // Coût total (somme des salaires des ouvriers sélectionnés)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Coût total du personnel',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${_coutTotalFromWorkers()} CFA',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Calculé à partir du salaire journalier de chaque ouvrier.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Boutons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _submit,
                    child: const Text('Enregistrer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
