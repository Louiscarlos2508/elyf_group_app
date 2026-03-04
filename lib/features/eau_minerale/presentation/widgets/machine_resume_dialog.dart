import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/machine.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/notification_service.dart';

/// Dialog pour remettre une machine en service après une panne.
class MachineResumeDialog extends ConsumerStatefulWidget {
  const MachineResumeDialog({
    super.key,
    required this.machine,
  });

  final Machine machine;

  @override
  ConsumerState<MachineResumeDialog> createState() => _MachineResumeDialogState();
}

class _MachineResumeDialogState extends ConsumerState<MachineResumeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      // 1. Mettre à jour le statut de la machine
      final machineMiseAJour = widget.machine.copyWith(
        isActive: true,
        updatedAt: DateTime.now(),
      );
      
      final machineController = ref.read(machineControllerProvider);
      await machineController.updateMachine(machineMiseAJour);

      // 2. Invalider les providers pour rafraîchir les listes (UI)
      ref.invalidate(allMachinesProvider);
      ref.invalidate(productionSessionsStateProvider);

      if (mounted) {
        Navigator.of(context).pop();
        NotificationService.showInfo(context, 'Machine remise en service avec succès');
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, 'Erreur lors de la remise en service : $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Icon(Icons.check_circle_outline, color: colors.primary),
          const SizedBox(width: 12),
          const Text('Remise en service'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirmez-vous que la machine "${widget.machine.name}" est réparée et prête à reprendre la production ?',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes de réparation (optionnel)',
                hintText: 'Ex: Remplacement du joint hydraulique...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.note_alt_outlined),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('REMETTRE EN SERVICE'),
        ),
      ],
    );
  }
}
