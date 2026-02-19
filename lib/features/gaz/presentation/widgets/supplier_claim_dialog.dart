
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared.dart';
import '../../application/providers.dart';
import '../../domain/entities/cylinder_leak.dart';

/// Dialogue pour générer un rapport de réclamation fournisseur.
class SupplierClaimDialog extends ConsumerStatefulWidget {
  const SupplierClaimDialog({
    super.key,
    required this.enterpriseId,
  });

  final String enterpriseId;

  @override
  ConsumerState<SupplierClaimDialog> createState() => _SupplierClaimDialogState();
}

class _SupplierClaimDialogState extends ConsumerState<SupplierClaimDialog> {
  bool _isSubmitting = false;

  Future<void> _markAsSent(Map<int, List<CylinderLeak>> summary) async {
    setState(() => _isSubmitting = true);
    try {
      final allIds = summary.values
          .expand((leaks) => leaks)
          .map((l) => l.id)
          .toList();

      await ref.read(leakReportControllerProvider)
          .submitClaim(allIds);
      
      ref.invalidate(leakReportSummaryProvider(widget.enterpriseId));

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fuites marquées comme envoyées au fournisseur')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(leakReportSummaryProvider(widget.enterpriseId));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.assignment_outlined, color: Colors.orange),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Réclamation Fournisseur',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Résumé des bouteilles vides avec fuites à échanger chez le fournisseur.',
                style: TextStyle(color: Colors.grey),
              ),
              const Divider(height: 32),
              
              Expanded(
                child: summaryAsync.when(
                  data: (summary) {
                    if (summary.isEmpty) {
                      return const Center(
                        child: Text('Aucune fuite en attente de réclamation.'),
                      );
                    }

                    return Column(
                      children: [
                        Table(
                          columnWidths: const {
                            0: FlexColumnWidth(2),
                            1: FlexColumnWidth(1),
                          },
                          children: [
                            const TableRow(
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text('Format (kg)', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text('Quantité', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                                ),
                              ],
                            ),
                            ...summary.entries.map((entry) => TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text('${entry.key} kg'),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text('${entry.value.length}', textAlign: TextAlign.right),
                                ),
                              ],
                            )),
                            TableRow(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Text(
                                    '${summary.values.fold(0, (sum, list) => sum + list.length)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElyfButton(
                              onPressed: () => Navigator.of(context).pop(),
                              variant: ElyfButtonVariant.text,
                              child: const Text('Fermer'),
                            ),
                            const SizedBox(width: 8),
                            ElyfButton(
                              onPressed: _isSubmitting ? null : () => _markAsSent(summary),
                              isLoading: _isSubmitting,
                              child: const Text('Marquer comme envoyé'),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Erreur: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
