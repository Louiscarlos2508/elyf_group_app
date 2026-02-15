import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../domain/entities/gas_sale.dart';
import '../../application/providers.dart';
import '../../application/controllers/dispatch_controller.dart';

/// Carte d'affichage d'une vente en gros avec informations de tour et grossiste.
class WholesaleSaleCard extends StatelessWidget {
  const WholesaleSaleCard({super.key, required this.sale});

  final GasSale sale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec date et montant
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateFormat.format(sale.saleDate),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: const Color(0xFF6A7282),
                      ),
                    ),
                    if (sale.wholesalerName != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.business,
                            size: 16,
                            color: Color(0xFF3B82F6), // Blue
                          ),
                          const SizedBox(width: 4),
                          Text(
                            sale.wholesalerName!,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (sale.tourId != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.local_shipping,
                            size: 16,
                            color: Color(0xFF10B981), // Emerald
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Tour d\'approvisionnement',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              color: const Color(0xFF6A7282),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  CurrencyFormatter.formatDouble(sale.totalAmount),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Détails de la vente
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.05),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _DetailItem(
                    icon: Icons.inventory_2,
                    label: 'Quantité',
                    value: '${sale.quantity}',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _DetailItem(
                    icon: Icons.attach_money,
                    label: 'Prix unitaire',
                    value: CurrencyFormatter.formatDouble(sale.unitPrice),
                  ),
                ),
              ],
            ),
          ),
          if (sale.notes != null && sale.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note, size: 16, color: Color(0xFF3B82F6)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sale.notes!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: const Color(0xFF6A7282),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          // Delivery section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DeliveryStatusBadge(status: sale.deliveryStatus),
              if (sale.deliveryStatus == DeliveryStatus.pending)
                Consumer(
                  builder: (context, ref, _) {
                    return ElevatedButton.icon(
                      onPressed: () => _showDispatchDialog(context, ref),
                      icon: const Icon(Icons.send, size: 16),
                      label: const Text('Expédier'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
          if (sale.deliveryPersonId != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 14, color: Color(0xFF6A7282)),
                const SizedBox(width: 4),
                Text(
                  'Livreur ID: ${sale.deliveryPersonId}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: const Color(0xFF6A7282),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showDispatchDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _DispatchDialog(sale: sale),
    );
  }
}

class _DeliveryStatusBadge extends StatelessWidget {
  const _DeliveryStatusBadge({required this.status});
  final DeliveryStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      DeliveryStatus.pending => (const Color(0xFFF97316), Icons.hourglass_empty),
      DeliveryStatus.inProgress => (const Color(0xFF3B82F6), Icons.local_shipping),
      DeliveryStatus.delivered => (const Color(0xFF10B981), Icons.check_circle),
      DeliveryStatus.cancelled => (const Color(0xFFEF4444), Icons.cancel),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DispatchDialog extends ConsumerStatefulWidget {
  const _DispatchDialog({required this.sale});
  final GasSale sale;

  @override
  ConsumerState<_DispatchDialog> createState() => _DispatchDialogState();
}

class _DispatchDialogState extends ConsumerState<_DispatchDialog> {
  String? _selectedUserId;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(dispatchControllerProvider);
    
    return AlertDialog(
      title: const Text('Assigner la livraison'),
      content: FutureBuilder<List<String>>(
        future: controller.getAvailableDeliveryPersons(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final userIds = snapshot.data ?? [];
          if (userIds.isEmpty) {
            return const Text('Aucun livreur disponible.');
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Sélectionnez un livreur pour expédier cette commande.'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedUserId,
                items: userIds.map((id) => DropdownMenuItem(
                  value: id,
                  child: Text('Livreur: $id'),
                )).toList(),
                onChanged: (val) => setState(() => _selectedUserId = val),
                decoration: const InputDecoration(
                  labelText: 'Livreur',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _selectedUserId == null || _isLoading
              ? null
              : () async {
                  setState(() => _isLoading = true);
                  try {
                    final currentUserId = ref.read(currentUserIdProvider);
                    await controller.assignDelivery(
                      widget.sale.id,
                      _selectedUserId!,
                      currentUserId,
                    );
                    if (context.mounted) Navigator.pop(context);
                  } finally {
                    if (context.mounted) setState(() => _isLoading = false);
                  }
                },
          child: const Text('Assigner'),
        ),
      ],
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF6A7282)),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: const Color(0xFF6A7282),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF101828),
          ),
        ),
      ],
    );
  }
}
