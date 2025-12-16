import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/bobine_usage.dart';
import '../../domain/entities/production_session.dart';

/// Dialog pour signaler qu'une bobine est finie.
class BobineFinishDialog extends ConsumerStatefulWidget {
  const BobineFinishDialog({
    super.key,
    required this.session,
    required this.bobine,
    required this.onFinished,
  });

  final ProductionSession session;
  final BobineUsage bobine;
  final ValueChanged<ProductionSession> onFinished;

  @override
  ConsumerState<BobineFinishDialog> createState() =>
      _BobineFinishDialogState();
}

class _BobineFinishDialogState extends ConsumerState<BobineFinishDialog> {
  bool _isLoading = false;

  Future<void> _submit() async {
    setState(() => _isLoading = true);

    try {
      // Mettre à jour la bobine pour la marquer comme finie
      final bobinesMisesAJour = widget.session.bobinesUtilisees.map((b) {
        if (b.bobineType == widget.bobine.bobineType && 
            b.machineId == widget.bobine.machineId) {
          return b.copyWith(
            estFinie: true,
            dateUtilisation: DateTime.now(),
          );
        }
        return b;
      }).toList();

      final sessionMiseAJour = widget.session.copyWith(
        bobinesUtilisees: bobinesMisesAJour,
        updatedAt: DateTime.now(),
      );

      // Sauvegarder la session
      final controller = ref.read(productionSessionControllerProvider);
      final sessionSauvegardee = await controller.updateSession(sessionMiseAJour);

      // Invalider le provider pour rafraîchir les données et éviter de réutiliser cette bobine
      ref.invalidate(productionSessionsStateProvider);

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onFinished(sessionSauvegardee);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bobine ${widget.bobine.bobineType} marquée comme finie',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Bobine finie',
                    style: theme.textTheme.headlineSmall?.copyWith(
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
            const SizedBox(height: 8),
            Text(
              'Signalez que la bobine ${widget.bobine.bobineType} est finie.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Card(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      context,
                      'Machine',
                      widget.bobine.machineName,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      context,
                      'Type',
                      widget.bobine.bobineType,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Confirmer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
