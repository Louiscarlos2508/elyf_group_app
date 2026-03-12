import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/machine_material_usage.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/notification_service.dart';

/// Dialog pour signaler qu'une matière est finie.
/// (Anciennement BobineFinishDialog).
class MachineMaterialFinishDialog extends ConsumerStatefulWidget {
  const MachineMaterialFinishDialog({
    super.key,
    required this.session,
    required this.material,
    required this.onFinished,
  });

  final ProductionSession session;
  final MachineMaterialUsage material;
  final ValueChanged<ProductionSession> onFinished;

  @override
  ConsumerState<MachineMaterialFinishDialog> createState() => _MachineMaterialFinishDialogState();
}

class _MachineMaterialFinishDialogState extends ConsumerState<MachineMaterialFinishDialog> {
  bool _isLoading = false;

  Future<void> _submit() async {
    setState(() => _isLoading = true);

    try {
      final materialsMisesAJour = widget.session.machineMaterials.map((m) {
        if (m.id == widget.material.id) {
          return m.copyWith(estFinie: true, dateUtilisation: DateTime.now());
        }
        return m;
      }).toList();

      final sessionMiseAJour = widget.session.copyWith(
        machineMaterials: materialsMisesAJour,
        updatedAt: DateTime.now(),
      );

      final controller = ref.read(productionSessionControllerProvider);
      final sessionSauvegardee = await controller.updateSession(
        sessionMiseAJour,
      );

      ref.invalidate(productionSessionsStateProvider);

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onFinished(sessionSauvegardee);

      NotificationService.showSuccess(
        context,
        'Matière ${widget.material.materialType} marquée comme finie',
      );
    } catch (e) {
      if (!mounted) return;
      NotificationService.showError(context, e.toString());
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
                    'Matière finie',
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
              'Signalez que la matière ${widget.material.materialType} est finie.',
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
                      widget.material.machineName,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(context, 'Type', widget.material.materialType),
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
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
