import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../stock_transfer_dialog.dart';
import '../replenishment_dialog.dart';

/// En-tête de la carte de stock d'un point de vente.
class PosStockHeader extends StatelessWidget {
  const PosStockHeader({super.key, required this.enterprise});

  final Enterprise enterprise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              // Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.store,
                  size: 20,
                  color: Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      enterprise.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: const Color(0xFF0A0A0A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      enterprise.address ?? 'Aucune adresse',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: const Color(0xFF6A7282),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '📞 ${enterprise.phone ?? "Aucun téléphone"}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: const Color(0xFF99A1AF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Status badge & Actions
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF030213),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                enterprise.isActive ? 'Actif' : 'Inactif',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (enterprise.parentEnterpriseId != null)
              ElyfButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => StockTransferDialog(
                    fromEnterpriseId: enterprise.parentEnterpriseId ?? '',
                    initialToEnterpriseId: enterprise.id,
                  ),
                ),
                variant: ElyfButtonVariant.outlined,
                size: ElyfButtonSize.small,
                icon: Icons.local_shipping,
                child: const Text('Ravitaillement'),
              ),
          ],
        ),
      ],
    );
  }
}
