import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import '../../../application/controllers/dispatch_controller.dart';
import '../../../domain/entities/gas_sale.dart';
import '../../widgets/gaz_header.dart';
import '../../widgets/signature_pad.dart';

/// Écran de workflow pour les livreurs.
class GazDeliveryWorkflowScreen extends ConsumerWidget {
  const GazDeliveryWorkflowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUserId = ref.watch(currentUserIdProvider);
    final salesAsync = ref.watch(gasSalesProvider);

    return CustomScrollView(
      slivers: [
        const GazHeader(
          title: 'LIVRAISONS',
          subtitle: 'Mes livraisons en cours',
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: salesAsync.when(
              data: (allSales) {
                final myDeliveries = allSales
                    .where((s) =>
                        s.deliveryPersonId == currentUserId &&
                        (s.deliveryStatus == DeliveryStatus.inProgress ||
                            s.deliveryStatus == DeliveryStatus.pending))
                    .toList()
                  ..sort((a, b) => b.saleDate.compareTo(a.saleDate));

                if (myDeliveries.isEmpty) {
                  return _EmptyDeliveries();
                }

                return Column(
                  children: myDeliveries
                      .map((sale) => _DeliveryTaskCard(sale: sale))
                      .toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, __) => Center(child: Text('Erreur: $e')),
            ),
          ),
        ),
      ],
    );
  }
}

class _DeliveryTaskCard extends ConsumerWidget {
  const _DeliveryTaskCard({required this.sale});
  final GasSale sale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.watch(dispatchControllerProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  sale.wholesalerName ?? 'Client inconnu',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                _StatusChip(status: sale.deliveryStatus),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Color(0xFF6A7282)),
                const SizedBox(width: 4),
                Text(
                  sale.customerPhone ?? 'Pas de téléphone',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quantité', style: theme.textTheme.bodySmall),
                    Text('${sale.quantity} bouteilles', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: [
                    if (sale.deliveryStatus == DeliveryStatus.inProgress)
                      ElevatedButton(
                        onPressed: () => _updateStatus(context, controller, DeliveryStatus.delivered, currentUserId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Marquer Livré'),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, DispatchController controller, DeliveryStatus status, String userId) async {
    if (status == DeliveryStatus.delivered) {
      final signature = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Signature du client'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Veuillez faire signer le client pour confirmer la réception.'),
                const SizedBox(height: 16),
                SignaturePad(
                  onSign: (base64) => Navigator.pop(context, base64),
                ),
              ],
            ),
          ),
        ),
      );

      if (signature == null) return;

      try {
        await controller.updateStatus(sale.id, status, userId, proofOfDelivery: signature);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Livraison confirmée avec signature')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    } else {
      // Logic for other status updates if needed
      try {
        await controller.updateStatus(sale.id, status, userId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Statut mis à jour avec succès')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final DeliveryStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status == DeliveryStatus.inProgress ? const Color(0xFF3B82F6) : const Color(0xFFF97316);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _EmptyDeliveries extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, size: 64, color: Color(0xFFD1D5DB)),
          const SizedBox(height: 16),
          Text(
            'Aucune livraison en cours',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: const Color(0xFF6A7282)),
          ),
        ],
      ),
    );
  }
}
