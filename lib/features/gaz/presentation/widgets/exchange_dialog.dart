import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/cylinder.dart';
import '../../domain/entities/exchange_record.dart';
import '../../../../../shared.dart';
import '../../application/providers.dart';
import '../../../../../core/tenant/tenant_provider.dart' show activeEnterpriseProvider;
import '../../../../../core/auth/providers.dart';

/// Dialogue pour enregistrer un échange de bouteilles vides (Inter-marques).
class ExchangeDialog extends ConsumerStatefulWidget {
  const ExchangeDialog({super.key});

  @override
  ConsumerState<ExchangeDialog> createState() => _ExchangeDialogState();
}

class _ExchangeDialogState extends ConsumerState<ExchangeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');
  final _notesController = TextEditingController();
  
  Cylinder? _fromCylinder;
  Cylinder? _toCylinder;
  bool _isLoading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _fromCylinder == null || _toCylinder == null) return;
    
    if (_fromCylinder!.id == _toCylinder!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les deux bouteilles doivent être différentes'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = ref.read(authControllerProvider);
      final enterpriseId = ref.read(activeEnterpriseProvider).value?.id ?? '';
      
      final exchange = ExchangeRecord(
        id: '', // Généré par le repository
        enterpriseId: enterpriseId,
        fromCylinderId: _fromCylinder!.id,
        toCylinderId: _toCylinder!.id,
        quantity: int.parse(_quantityController.text),
        exchangedAt: DateTime.now(),
        notes: _notesController.text,
        reportedBy: auth.currentUser?.id,
      );

      await ref.read(transactionServiceProvider).executeExchangeTransaction(
        exchange: exchange,
        userId: auth.currentUser?.id ?? '',
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échange enregistré avec succès')),
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
        constraints: const BoxConstraints(maxWidth: 450),
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
                          color: Theme.of(context).colorScheme.secondaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.swap_horiz, color: Theme.of(context).colorScheme.secondary),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Échange de bouteilles',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Bouteille Donnée
                  cylindersAsync.when(
                    data: (cylinders) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Bouteille SORTIE (Donnée)', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<Cylinder>(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.upload_outlined),
                          ),
                          initialValue: _fromCylinder,
                          items: cylinders.map((c) => DropdownMenuItem(
                            value: c,
                            child: Text('${c.weight} kg'),
                          )).toList(),
                          onChanged: (val) => setState(() => _fromCylinder = val),
                          validator: (val) => val == null ? 'Requis' : null,
                        ),
                        const SizedBox(height: 16),
                        const Icon(Icons.arrow_downward, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('Bouteille ENTRÉE (Reçue)', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<Cylinder>(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.download_outlined),
                          ),
                          initialValue: _toCylinder,
                          items: cylinders.map((c) => DropdownMenuItem(
                            value: c,
                            child: Text('${c.weight} kg'),
                          )).toList(),
                          onChanged: (val) => setState(() => _toCylinder = val),
                          validator: (val) => val == null ? 'Requis' : null,
                        ),
                      ],
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Erreur: $e'),
                  ),
                  const SizedBox(height: 16),

                  // Quantité
                  TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantité',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.tag),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Requis';
                      final qty = int.tryParse(val);
                      if (qty == null || qty <= 0) return 'Invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Raison de l\'échange',
                      border: OutlineInputBorder(),
                      hintText: 'Ex: Échange Total vs Shell...',
                    ),
                    maxLines: 2,
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
                        child: const Text('Confirmer l\'échange'),
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
