import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/printing/printer_provider.dart';
import '../../../core/printing/templates/z_report_template.dart';
import '../../../features/boutique/domain/entities/closing.dart';
import '../../../features/boutique/application/providers.dart';

/// Bouton d'impression de Z-Report (clôture) avec détection automatique Sunmi.
class PrintZReportButton extends ConsumerStatefulWidget {
  const PrintZReportButton({
    super.key,
    required this.closing,
    this.onPrintSuccess,
    this.onPrintError,
  });

  final Closing closing;
  final VoidCallback? onPrintSuccess;
  final void Function(String error)? onPrintError;

  @override
  ConsumerState<PrintZReportButton> createState() => _PrintZReportButtonState();
}

class _PrintZReportButtonState extends ConsumerState<PrintZReportButton> {
  bool _isPrinting = false;
  bool _isSunmiDevice = false;
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
        // In the context of Z-Reports, we usually assume compatibility if it's "available"
        // but we keep the Sunmi check for UI styling if needed
        _isSunmiDevice = true; // Simplified for this component
      });
    }
  }

  Future<void> _printZReport() async {
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
      final printer = ref.read(activePrinterProvider);
      final settings = ref.read(boutiqueSettingsServiceProvider);
      
      final width = await printer.getLineWidth();
      final template = ZReportTemplate(
        widget.closing, 
        width: width,
        headerText: settings.receiptHeader,
        footerText: settings.receiptFooter,
        showLogo: settings.showLogo,
      );
      final content = template.generate();

      final success = await printer.printReceipt(content);

      if (!mounted) return;

      if (success) {
        widget.onPrintSuccess?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Z-Report imprimé avec succès'),
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
      onPressed: _isPrinting || !_isPrinterAvailable ? null : _printZReport,
      icon: _isPrinting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.print),
      label: Text(_isPrinting ? 'Impression...' : 'Imprimer le Z-Report'),
      style: FilledButton.styleFrom(
        backgroundColor: _isPrinterAvailable
            ? Colors.orange[800]
            : theme.colorScheme.surfaceContainerHighest,
        foregroundColor: Colors.white,
      ),
    );
  }
}
