import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/contract.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/tenant.dart';
import 'contract_card_helpers.dart';
import 'contract_detail/contract_detail_header.dart';
import 'contract_detail/contract_detail_status_banner.dart';
import 'contract_detail/contract_detail_sections.dart';
import 'contract_detail/contract_detail_payments.dart';
import 'contract_detail/contract_detail_actions.dart';

/// Dialog de détails d'un contrat avec liens vers locataire et propriété.
class ContractDetailDialog extends ConsumerWidget {
  const ContractDetailDialog({
    super.key,
    required this.contract,
    this.onTenantTap,
    this.onPropertyTap,
    this.onPaymentTap,
    this.onDelete,
  });

  final Contract contract;
  final void Function(Tenant)? onTenantTap;
  final void Function(Property)? onPropertyTap;
  final void Function(Payment)? onPaymentTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = ContractCardHelpers.getStatusColor(contract.status);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ContractDetailHeader(contract: contract, statusColor: statusColor),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ContractStatusBanner(
                      contract: contract,
                      statusColor: statusColor,
                    ),
                    const SizedBox(height: 16),
                    ContractDatesSection(contract: contract),
                    const SizedBox(height: 16),
                    ContractFinancialSection(contract: contract),
                    const SizedBox(height: 16),
                    ContractLinkedEntitiesSection(
                      contract: contract,
                      onTenantTap: onTenantTap,
                      onPropertyTap: onPropertyTap,
                    ),
                    const SizedBox(height: 16),
                    ContractPaymentsSection(
                      contractId: contract.id,
                      onPaymentTap: onPaymentTap,
                    ),
                    if (contract.notes != null &&
                        contract.notes!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ContractNotesSection(notes: contract.notes!),
                    ],
                  ],
                ),
              ),
            ),
            ContractDetailActions(contract: contract, onDelete: onDelete),
          ],
        ),
      ),
    );
  }
}
