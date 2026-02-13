import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';

import 'package:elyf_groupe_app/core/pdf/immobilier_report_pdf_service.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../application/providers.dart';
import '../../domain/entities/tenant.dart';

class TenantBalanceReportDialog extends ConsumerStatefulWidget {
  const TenantBalanceReportDialog({
    super.key,
    required this.tenant,
  });

  final Tenant tenant;

  @override
  ConsumerState<TenantBalanceReportDialog> createState() => _TenantBalanceReportDialogState();
}

class _TenantBalanceReportDialogState extends ConsumerState<TenantBalanceReportDialog> {
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, 1, 1); // Start of current year
    _endDate = now;
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _generateReport() async {
    setState(() => _isLoading = true);
    try {
      final contracts = await ref.read(contractsProvider.future);
      final payments = await ref.read(paymentsWithRelationsProvider.future);

      final pdfService = ImmobilierReportPdfService.instance;
      final file = await pdfService.generateTenantBalanceReport(
        tenant: widget.tenant,
        contracts: contracts,
        payments: payments,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        final result = await OpenFile.open(file.path);
        if (result.type != ResultType.done && mounted) {
           NotificationService.showInfo(context, 'PDF généré: ${file.path}');
        }
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, 'Erreur lors de la génération: $e');
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
      title: const Text('Relevé de Compte'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Générer le relevé pour ${widget.tenant.fullName}'),
          const SizedBox(height: 16),
          _DateSelector(
            label: 'Du',
            date: _startDate,
            onTap: () => _selectDate(context, true),
          ),
          const SizedBox(height: 8),
          _DateSelector(
            label: 'Au',
            date: _endDate,
            onTap: () => _selectDate(context, false),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton.icon(
          onPressed: _isLoading ? null : _generateReport,
          icon: _isLoading 
              ? const SizedBox(
                  width: 16, 
                  height: 16, 
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                ) 
              : const Icon(Icons.picture_as_pdf),
          label: const Text('Générer PDF'),
        ),
      ],
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            Text(
              '${date.day}/${date.month}/${date.year}',
              style: const TextStyle(fontSize: 16),
            ),
            const Spacer(),
            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
