import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';

import '../../../domain/entities/sale.dart';
import 'invoice_print_service.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/utils/notification_service.dart';

/// Widget bouton d'impression pour les factures eau minérale.
class EauMineralePrintButton extends StatefulWidget {
  const EauMineralePrintButton({
    super.key,
    required this.sale,
    this.compact = false,
  });

  final Sale sale;
  final bool compact;

  @override
  State<EauMineralePrintButton> createState() => _EauMineralePrintButtonState();
}

class _EauMineralePrintButtonState extends State<EauMineralePrintButton> {
  bool _isPrinting = false;
  bool _isSunmiAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkSunmi();
  }

  Future<void> _checkSunmi() async {
    final available = await EauMineraleInvoiceService.instance
        .isSunmiAvailable();
    if (mounted) {
      setState(() => _isSunmiAvailable = available);
    }
  }

  Future<void> _showPrintOptions() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Générer PDF'),
              subtitle: const Text('Créer un fichier PDF'),
              onTap: () => Navigator.pop(context, 'pdf'),
            ),
            if (_isSunmiAvailable)
              ListTile(
                leading: const Icon(Icons.print),
                title: const Text('Imprimer (Sunmi)'),
                subtitle: const Text('Imprimante thermique'),
                onTap: () => Navigator.pop(context, 'sunmi'),
              ),
          ],
        ),
      ),
    );

    if (result == null || !mounted) return;

    setState(() => _isPrinting = true);

    try {
      if (result == 'pdf') {
        final file = await EauMineraleInvoiceService.instance.generateSalePdf(
          widget.sale,
        );
        if (!mounted || !context.mounted) return;
        await OpenFile.open(file.path);
        if (!mounted || !context.mounted) return;
        NotificationService.showSuccess(context, 'PDF généré avec succès');
      } else if (result == 'sunmi') {
        final success = await EauMineraleInvoiceService.instance
            .printSaleInvoice(widget.sale);
        if (!mounted || !context.mounted) return;
        if (success) {
          NotificationService.showSuccess(context, 'Facture imprimée');
        } else {
          NotificationService.showError(context, 'Erreur d\'impression');
        }
      }
    } catch (e) {
      if (!mounted || !context.mounted) return;
      NotificationService.showError(context, 'Erreur: $e');
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return IconButton(
        onPressed: _isPrinting ? null : _showPrintOptions,
        icon: _isPrinting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.print),
        tooltip: 'Imprimer la facture',
      );
    }

    return FilledButton.tonal(
      onPressed: _isPrinting ? null : _showPrintOptions,
      child: _isPrinting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.print, size: 18),
                SizedBox(width: 8),
                Text('Imprimer'),
              ],
            ),
    );
  }
}
