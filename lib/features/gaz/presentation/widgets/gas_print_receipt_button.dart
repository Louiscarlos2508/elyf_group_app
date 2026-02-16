import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import '../../../../core/printing/printer_provider.dart';
import '../../../../core/tenant/tenant_provider.dart';
import '../../domain/entities/gas_sale.dart';

/// Bouton d'impression de reçu pour le gaz.
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
    final printer = ref.read(thermalPrinterServiceProvider);
    final isAvailable = await printer.isAvailable();

    if (mounted) {
      setState(() {
        _isPrinterAvailable = isAvailable;
      });
    }
  }

  Future<void> _printReceipt() async {
    final printingService = ref.read(gazPrintingServiceProvider);
    final theme = Theme.of(context);
    
    setState(() => _isPrinting = true);

    // Show full-screen blurred overlay (Story 5.3)
    final overlay = showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'IMPRESSION DU REÇU EN COURS',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Merci de patienter...',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final enterpriseName = ref.read(activeEnterpriseProvider).value?.name;
      
      final success = await printingService.printSaleReceipt(
        sale: widget.sale,
        cylinderLabel: widget.cylinderLabel,
        enterpriseName: enterpriseName,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Close overlay

      if (success) {
        widget.onPrintSuccess?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reçu imprimé avec succès'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        widget.onPrintError?.call('Erreur lors de l\'impression');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'impression. Vérifiez l\'imprimante.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close overlay on error
      }
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
      label: Text(_isPrinting ? 'Impression...' : 'Imprimer le reçu'),
      style: FilledButton.styleFrom(
        backgroundColor: _isPrinterAvailable
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest,
      ),
    );
  }
}
