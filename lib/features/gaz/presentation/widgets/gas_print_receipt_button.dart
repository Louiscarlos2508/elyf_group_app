import 'package:flutter/material.dart';

import '../../../../core/printing/sunmi_v3_service.dart';
import '../../../../core/printing/templates/gas_receipt_template.dart';
import '../../domain/entities/gas_sale.dart';

/// Bouton d'impression de facture pour le gaz avec détection automatique Sunmi.
class GasPrintReceiptButton extends StatefulWidget {
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
  State<GasPrintReceiptButton> createState() => _GasPrintReceiptButtonState();
}

class _GasPrintReceiptButtonState extends State<GasPrintReceiptButton> {
  bool _isPrinting = false;
  bool _isSunmiDevice = false;
  bool _isPrinterAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkPrinterAvailability();
  }

  Future<void> _checkPrinterAvailability() async {
    final sunmi = SunmiV3Service.instance;
    final isSunmi = await sunmi.isSunmiDevice;
    final isAvailable = isSunmi && await sunmi.isPrinterAvailable();

    if (mounted) {
      setState(() {
        _isSunmiDevice = isSunmi;
        _isPrinterAvailable = isAvailable;
      });
    }
  }

  Future<void> _printReceipt() async {
    if (!_isPrinterAvailable) {
      widget.onPrintError?.call(
        _isSunmiDevice
            ? 'Imprimante non disponible'
            : 'Imprimante Sunmi non détectée',
      );
      return;
    }

    setState(() => _isPrinting = true);

    try {
      final template = GasReceiptTemplate(
        widget.sale,
        cylinderLabel: widget.cylinderLabel,
      );
      final content = template.generate();

      final success = await SunmiV3Service.instance.printReceipt(content);

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

    // Ne pas afficher le bouton si l'appareil n'est pas Sunmi
    if (!_isSunmiDevice) {
      return const SizedBox.shrink();
    }

    return FilledButton.icon(
      onPressed: _isPrinting || !_isPrinterAvailable ? null : _printReceipt,
      icon: _isPrinting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
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
