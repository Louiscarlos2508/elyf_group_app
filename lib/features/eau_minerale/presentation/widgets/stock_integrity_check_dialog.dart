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
                          result.productName,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ID: ${result.productId}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildAuditRow(
                              theme,
                              'Mouvements cumulés',
                              '(+) ${result.totalEntries} | (-) ${result.totalExits}',
                              isHeader: false,
                            ),
                            const Divider(height: 8),
                            _buildAuditRow(
                              theme,
                              'Solde Calculé (Σ Entrées - Σ Sorties)',
                              '${result.calculatedQuantity}',
                              isBold: true,
                            ),
                            if (result.hasPotentialDuplicate)
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Attention: Des mouvements existent peut-être sous un autre ID pour ce produit.",
                                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange.shade900),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            _buildAuditRow(
                              theme,
                              'Stock Actuel (Base de données)',
                              '${result.storedQuantity}',
                              trailing: !result.hasStoredRecord && result.calculatedQuantity != 0
                                ? const Tooltip(
                                    message: "Snapshot manquant dans la base locale",
                                    child: Icon(Icons.sync_problem, color: Colors.orange, size: 16),
                                  )
                                : null,
                            ),
                            if (!result.isValid) ...[
                              _buildAuditRow(
                                theme,
                                'Écart (Discrepancy)',
                                result.discrepancy?.toStringAsFixed(2) ?? '0.00',
                                color: theme.colorScheme.error,
                                isBold: true,
                              ),
                            ],
                            if (result.hasPotentialDuplicate) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Attention: Des mouvements avec le même nom mais un ID différent ont été détectés. Cela peut fausser le stock affiché.',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.orange.shade900,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (result.hadNegativeBalance) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, size: 14, color: theme.colorScheme.error),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Alerte: Solde négatif détecté dans l\'historique',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.error,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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

  Widget _buildAuditRow(
    ThemeData theme,
    String label,
    String value, {
    Color? color,
    bool isBold = false,
    bool isHeader = false,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isHeader ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              fontWeight: isHeader ? FontWeight.bold : null,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: isBold || isHeader ? FontWeight.bold : FontWeight.w500,
                  color: color ?? (isBold ? theme.colorScheme.primary : theme.colorScheme.onSurface),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 4),
                trailing,
              ],
            ],
          ),
        ],
      ),
    );
  }
}
