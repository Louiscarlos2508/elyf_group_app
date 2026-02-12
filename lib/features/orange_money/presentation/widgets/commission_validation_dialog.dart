import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../application/providers.dart';
import '../../domain/entities/commission.dart';
import '../widgets/commission_discrepancy_indicator.dart';
import '../widgets/commission_status_badge.dart';

/// Dialog for validating declared commissions (Supervisor/Manager)
class CommissionValidationDialog extends ConsumerStatefulWidget {
  final Commission commission;

  const CommissionValidationDialog({
    super.key,
    required this.commission,
  });

  @override
  ConsumerState<CommissionValidationDialog> createState() =>
      _CommissionValidationDialogState();
}

class _CommissionValidationDialogState
    extends ConsumerState<CommissionValidationDialog> {
  final _validationNotesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _validationNotesController.dispose();
    super.dispose();
  }

  Future<void> _handleValidate() async {
    try {
      setState(() => _isLoading = true);

      final userId = ref.read(currentUserIdProvider);

      await ref.read(commissionServiceProvider).validateCommission(
            commissionId: widget.commission.id,
            validatedBy: userId,
            notes: _validationNotesController.text.isNotEmpty
                ? _validationNotesController.text
                : null,
          );

      if (mounted) {
        NotificationService.showSuccess(context, 'Commission validée avec succès');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, 'Erreur: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleDispute() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Marquer en Litige'),
        content: const Text(
          'Êtes-vous sûr de vouloir marquer cette commission en litige ? '
          'Cette action nécessitera une investigation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _isLoading = true);

      final reason = _validationNotesController.text.isNotEmpty
          ? _validationNotesController.text
          : 'Écart significatif détecté - Investigation requise';

      await ref.read(commissionServiceProvider).markAsDisputed(
            commissionId: widget.commission.id,
            reason: reason,
          );

      if (mounted) {
        NotificationService.showWarning(context, 'Commission marquée en litige');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, 'Erreur: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Expanded(
            child: Text('Valider Commission ${widget.commission.period}'),
          ),
          CommissionStatusBadge(
            status: widget.commission.status,
            discrepancyStatus: widget.commission.discrepancyStatus,
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Comparaison montants
              _buildComparisonCard(),

              const SizedBox(height: 16),

              // 2. Affichage écart
              if (widget.commission.discrepancy != null)
                CommissionDiscrepancyIndicator.fromCommission(
                  widget.commission,
                  showDetails: true,
                ),

              const SizedBox(height: 16),

              // 3. Screenshot SMS (cliquable pour agrandir)
              if (widget.commission.smsProofUrl != null)
                _buildSmsProofViewer(),

              const SizedBox(height: 16),

              // 4. Détails calcul système
              if (widget.commission.calculationDetails != null)
                _buildCalculationDetails(),

              const SizedBox(height: 16),

              // 5. Notes agent (si présentes)
              if (widget.commission.notes != null &&
                  widget.commission.notes!.isNotEmpty)
                _buildNotesCard('Notes Agent', widget.commission.notes!),

              const SizedBox(height: 16),

              // 6. Notes validation
              TextFormField(
                controller: _validationNotesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes de validation',
                  hintText: 'Commentaires sur la validation',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        // Bouton Disputer (si écart significatif)
        if (widget.commission.discrepancyStatus ==
            DiscrepancyStatus.ecartSignificatif)
          TextButton(
            onPressed: _isLoading ? null : _handleDispute,
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Marquer en Litige'),
          ),

        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),

        ElevatedButton(
          onPressed: _isLoading ? null : _handleValidate,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Valider'),
        ),
      ],
    );
  }

  Widget _buildComparisonCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comparaison Montants',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildAmountRow(
              'Estimé (Système)',
              widget.commission.estimatedAmount,
              Icons.calculate,
              Colors.blue,
            ),
            const Divider(height: 24),
            _buildAmountRow(
              'Déclaré (SMS)',
              widget.commission.declaredAmount ?? 0,
              Icons.message,
              Colors.green,
            ),
            const Divider(height: 24, thickness: 2),
            _buildAmountRow(
              'Écart',
              widget.commission.discrepancy ?? 0,
              Icons.compare_arrows,
              _getDiscrepancyColor(),
              isDiscrepancy: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountRow(
    String label,
    int amount,
    IconData icon,
    Color color, {
    bool isDiscrepancy = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.format(amount),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        if (isDiscrepancy && widget.commission.discrepancyPercentage != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${widget.commission.discrepancyPercentage!.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
      ],
    );
  }

  Color _getDiscrepancyColor() {
    final status = widget.commission.discrepancyStatus;
    switch (status) {
      case DiscrepancyStatus.conforme:
        return Colors.green;
      case DiscrepancyStatus.ecartMineur:
        return Colors.orange;
      case DiscrepancyStatus.ecartSignificatif:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSmsProofViewer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Screenshot SMS Orange Money',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            // Show full screen image
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(
                    title: const Text('SMS Proof'),
                    backgroundColor: Colors.black,
                  ),
                  body: Center(
                    child: InteractiveViewer(
                      child: CachedNetworkImage(
                        imageUrl: widget.commission.smsProofUrl!,
                        placeholder: (context, url) =>
                            const CircularProgressIndicator(),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                    ),
                  ),
                  backgroundColor: Colors.black,
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: widget.commission.smsProofUrl!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 200,
                color: Colors.grey.shade200,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                height: 200,
                color: Colors.grey.shade200,
                child: const Center(child: Icon(Icons.error)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap pour agrandir',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildCalculationDetails() {
    final details = widget.commission.calculationDetails!;

    return ExpansionTile(
      title: const Text(
        'Détails du Calcul Système',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _buildDetailRow(
                'Cash-In Total',
                CurrencyFormatter.format(details.totalCashIn),
              ),
              _buildDetailRow(
                'Commission Cash-In',
                CurrencyFormatter.format(details.cashInCommission),
              ),
              const Divider(),
              _buildDetailRow(
                'Cash-Out Total',
                CurrencyFormatter.format(details.totalCashOut),
              ),
              _buildDetailRow(
                'Commission Cash-Out',
                CurrencyFormatter.format(details.cashOutCommission),
              ),
              const Divider(thickness: 2),
              _buildDetailRow(
                'Total Estimé',
                CurrencyFormatter.format(widget.commission.estimatedAmount),
                isBold: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(String title, String notes) {
    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note, size: 16, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              notes,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
