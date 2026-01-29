import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../application/providers.dart';
import '../../domain/services/stock_integrity_service.dart';

/// Dialog pour vérifier et réparer l'intégrité des stocks.
class StockIntegrityCheckDialog extends ConsumerStatefulWidget {
  const StockIntegrityCheckDialog({super.key});

  @override
  ConsumerState<StockIntegrityCheckDialog> createState() =>
      _StockIntegrityCheckDialogState();
}

class _StockIntegrityCheckDialogState
    extends ConsumerState<StockIntegrityCheckDialog> {
  bool _isChecking = false;
  bool _isRepairing = false;
  List<StockIntegrityResult>? _results;

  Future<void> _checkIntegrity() async {
    setState(() {
      _isChecking = true;
      _results = null;
    });

    try {
      final integrityService = ref.read(stockIntegrityServiceProvider);
      final results = await integrityService.verifyAllStocks();

      if (!mounted) return;

      setState(() {
        _results = results;
        _isChecking = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isChecking = false);
      NotificationService.showError(
        context,
        'Erreur lors de la vérification: ${e.toString()}',
      );
    }
  }

  Future<void> _repairAll() async {
    if (_results == null || _results!.every((r) => r.isValid)) {
      NotificationService.showInfo(
        context,
        'Aucune réparation nécessaire',
      );
      return;
    }

    setState(() => _isRepairing = true);

    try {
      final integrityService = ref.read(stockIntegrityServiceProvider);
      final repairedCount = await integrityService.repairAllInvalidStocks();

      if (!mounted) return;

      setState(() {
        _isRepairing = false;
      });

      // Re-vérifier après réparation
      await _checkIntegrity();

      if (!mounted) return;

      NotificationService.showSuccess(
        context,
        '$repairedCount stock(s) réparé(s) avec succès',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isRepairing = false);
      NotificationService.showError(
        context,
        'Erreur lors de la réparation: ${e.toString()}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final invalidCount =
        _results?.where((r) => !r.isValid).length ?? 0;
    final validCount = _results?.where((r) => r.isValid).length ?? 0;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.verified_user,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Vérification d\'Intégrité des Stocks',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Vérifie que les quantités stockées correspondent à la somme des mouvements.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            if (_isChecking)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: LoadingIndicator(),
                ),
              )
            else if (_results == null)
              FilledButton.icon(
                onPressed: _checkIntegrity,
                icon: const Icon(Icons.search),
                label: const Text('Vérifier l\'Intégrité'),
              )
            else ...[
              // Résumé
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: invalidCount > 0
                      ? theme.colorScheme.errorContainer.withValues(alpha: 0.2)
                      : theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          invalidCount > 0
                              ? Icons.warning
                              : Icons.check_circle,
                          color: invalidCount > 0
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            invalidCount > 0
                                ? '$invalidCount incohérence(s) détectée(s)'
                                : 'Tous les stocks sont cohérents',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: invalidCount > 0
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_results!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${_results!.length} stock(s) vérifié(s) • '
                        '$validCount valide(s) • $invalidCount invalide(s)',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Liste des résultats
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _results!.length,
                  itemBuilder: (context, index) {
                    final result = _results![index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          result.isValid
                              ? Icons.check_circle
                              : Icons.error,
                          color: result.isValid
                              ? theme.colorScheme.primary
                              : theme.colorScheme.error,
                        ),
                        title: Text(
                          result.stockId,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Type: ${result.stockType}',
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              'Stocké: ${result.storedQuantity} • '
                              'Calculé: ${result.calculatedQuantity}',
                              style: theme.textTheme.bodySmall,
                            ),
                            if (result.movementsCount != null)
                              Text(
                                'Mouvements: ${result.movementsCount}',
                                style: theme.textTheme.bodySmall,
                              ),
                            if (!result.isValid && result.discrepancy != null)
                              Text(
                                'Différence: ${result.discrepancy}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        trailing: result.isValid
                            ? null
                            : Icon(
                                Icons.warning,
                                color: theme.colorScheme.error,
                              ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Boutons d'action
              if (invalidCount > 0) ...[
                FilledButton.icon(
                  onPressed: _isRepairing ? null : _repairAll,
                  icon: _isRepairing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.build),
                  label: Text(
                    _isRepairing
                        ? 'Réparation en cours...'
                        : 'Réparer Tous les Stocks',
                  ),
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton.icon(
                onPressed: _checkIntegrity,
                icon: const Icon(Icons.refresh),
                label: const Text('Re-vérifier'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
