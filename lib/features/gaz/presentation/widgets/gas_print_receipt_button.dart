
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/printing/printer_provider.dart';
import '../../../../core/printing/templates/gas_receipt_template.dart';
import '../../domain/entities/gas_sale.dart';

/// Bouton d'impression de facture pour le gaz supportant plusieurs imprimantes via activePrinterProvider.
class GasPrintReceiptButton extends ConsumerStatefulWidget {
  const GasPrintReceiptButton({
    super.key,
    required this.sale,
    this.cylinderLabel,
    this.onPrintSuccess,
    this.onPrintError,
  });

  final GasSale sale;
  final String? cylinderLabel;
  final VoidCallback? onPrintSuccess;
  final void Function(String error)? onPrintError;

  @override
  ConsumerState<GasPrintReceiptButton> createState() => _GasPrintReceiptButtonState();
}

class _GasPrintReceiptButtonState extends ConsumerState<GasPrintReceiptButton> {
  bool _isPrinting = false;
  bool _isPrinterAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkPrinterAvailability();
  }

  Future<void> _checkPrinterAvailability() async {
    final printer = ref.read(activePrinterProvider);
    final isAvailable = await printer.isAvailable();

    if (mounted) {
      setState(() {
        _isPrinterAvailable = isAvailable;
      });
    }
  }

  Future<void> _printReceipt() async {
    final printer = ref.read(activePrinterProvider);
    final isAvailable = await printer.isAvailable();

    if (!isAvailable) {
      widget.onPrintError?.call('Imprimante non disponible. Veuillez vérifier la connexion dans les réglages.');
      return;
    }

    setState(() => _isPrinting = true);

    try {
      final template = GasReceiptTemplate(
        widget.sale,
        cylinderLabel: widget.cylinderLabel,
      );
      final content = template.generate();

      final success = await printer.printReceipt(content);

      if (!mounted) return;

      if (success) {
        widget.onPrintSuccess?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Facture imprimée avec succès'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        widget.onPrintError?.call('Erreur lors de l\'impression');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'impression'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      widget.onPrintError?.call(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FilledButton.icon(
      onPressed: _isPrinting ? null : _printReceipt,
      icon: _isPrinting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.print),
      label: Text(_isPrinting ? 'Impression...' : 'Imprimer la facture'),
      style: FilledButton.styleFrom(
        backgroundColor: _isPrinterAvailable
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest,
      ),
    );
  }
}
