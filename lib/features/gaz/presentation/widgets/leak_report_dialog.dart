import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/cylinder.dart';
import '../../domain/entities/cylinder_leak.dart';
import '../../../../../shared.dart';
import '../../application/providers.dart';
import '../../../../../core/tenant/tenant_provider.dart' show activeEnterpriseProvider;
import '../../../../../core/auth/providers.dart';

/// Dialogue pour déclarer une fuite sur une bouteille.
class LeakReportDialog extends ConsumerStatefulWidget {
  const LeakReportDialog({
    super.key,
    this.source = LeakSource.store,
    this.tourId,
  });

  final LeakSource source;
  final String? tourId;

  @override
  ConsumerState<LeakReportDialog> createState() => _LeakReportDialogState();
}

class _LeakReportDialogState extends ConsumerState<LeakReportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _volumeController = TextEditingController();
  
  Cylinder? _selectedCylinder;
  bool _isFullLoss = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    _volumeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedCylinder == null) return;

    setState(() => _isLoading = true);

    try {
      final auth = ref.read(authControllerProvider);
      final enterpriseId = ref.read(activeEnterpriseProvider).value?.id ?? '';
      
      final leak = CylinderLeak(
        id: '', // Généré par le repository
        enterpriseId: enterpriseId,
        cylinderId: _selectedCylinder!.id,
        weight: _selectedCylinder!.weight,
        source: widget.source,
        reportedDate: DateTime.now(),
        status: LeakStatus.reported,
        tourId: widget.tourId,
        notes: _notesController.text,
        isFullLoss: _isFullLoss,
        estimatedLossVolume: _isFullLoss ? null : double.tryParse(_volumeController.text),
        reportedBy: auth.currentUser?.id,
      );

      await ref.read(transactionServiceProvider).executeLeakDeclaration(
        leak: leak,
        userId: auth.currentUser?.id ?? '',
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fuite déclarée avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cylindersAsync = ref.watch(cylindersProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.water_drop_outlined, color: Colors.red),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Déclarer une fuite',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Sélection cylindre
                  cylindersAsync.when(
                    data: (cylinders) => DropdownButtonFormField<Cylinder>(
                      decoration: const InputDecoration(
                        labelText: 'Bouteille concernée',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                      ),
                      value: _selectedCylinder,
                      items: cylinders.map((c) => DropdownMenuItem(
                        value: c,
                        child: Text('${c.weight} kg'),
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedCylinder = val),
                      validator: (val) => val == null ? 'Requis' : null,
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Erreur: $e'),
                  ),
                  const SizedBox(height: 16),

                  // Type de perte
                  SwitchListTile(
                    title: const Text('Perte totale'),
                    subtitle: const Text('La bouteille est considérée comme vide'),
                    value: _isFullLoss,
                    onChanged: (val) => setState(() => _isFullLoss = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                  
                  if (!_isFullLoss) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _volumeController,
                      decoration: const InputDecoration(
                        labelText: 'Volume perdu estimé (%)',
                        border: OutlineInputBorder(),
                        suffixText: '%',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Requis';
                        final vol = double.tryParse(val);
                        if (vol == null || vol <= 0 || vol > 100) return 'Invalide';
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes / Observations',
                      border: OutlineInputBorder(),
                      hintText: 'Ex: Trouvé au fond du magasin...',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElyfButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        variant: ElyfButtonVariant.text,
                        child: const Text('Annuler'),
                      ),
                      const SizedBox(width: 8),
                      ElyfButton(
                        onPressed: _isLoading ? null : _submit,
                        isLoading: _isLoading,
                        child: const Text('Déclarer'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
