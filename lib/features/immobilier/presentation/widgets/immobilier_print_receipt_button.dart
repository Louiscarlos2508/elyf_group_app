import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/core/printing/printer_provider.dart';
import 'package:elyf_groupe_app/core/services/sunmi_print_service.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';
import '../../domain/entities/payment.dart';
import 'payment_card_helpers.dart';

/// Bouton d'impression de reçu pour l'immobilier avec surcouche floue (style Gaz).
class ImmobilierPrintReceiptButton extends ConsumerStatefulWidget {
  const ImmobilierPrintReceiptButton({
    super.key,
    required this.payment,
    this.onPrintSuccess,
    this.onPrintError,
  });

  final Payment payment;
  final VoidCallback? onPrintSuccess;
  final void Function(String error)? onPrintError;

  @override
  ConsumerState<ImmobilierPrintReceiptButton> createState() => _ImmobilierPrintReceiptButtonState();
}

class _ImmobilierPrintReceiptButtonState extends ConsumerState<ImmobilierPrintReceiptButton> {
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
    final theme = Theme.of(context);
    
    setState(() => _isPrinting = true);

    // Afficher l'overlay flou (identique au module Gaz)
    showDialog(
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
      final enterpriseName = ref.read(activeEnterpriseProvider).value?.name ?? 'ELYF GROUP';
      final payment = widget.payment;
      
      final success = await SunmiPrintService.instance.printImmobilierPaymentReceipt(
        enterpriseName: enterpriseName,
        receiptNumber: payment.receiptNumber ?? payment.id.substring(0, 8),
        paymentDate: payment.paymentDate,
        amount: payment.amount.toDouble(),
        paymentMethod: payment.paymentMethod.label,
        tenantName: payment.contract?.tenant?.fullName ?? 'Locataire',
        propertyAddress: payment.contract?.property?.address ?? 'Propriété',
        period: payment.month != null && payment.year != null 
            ? '${PaymentCardHelpers.getMonthName(payment.month!)} ${payment.year}'
            : null,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Fermer l'overlay

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
            content: Text('Erreur lors de l\'impression. Vérifiez l\'imprimante.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Fermer l'overlay en cas d'erreur
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
      label: Text(_isPrinting ? 'Impression...' : 'Imprimer la facture'),
      style: FilledButton.styleFrom(
        backgroundColor: _isPrinterAvailable
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest,
        minimumSize: const Size(180, 48), // Taille minimale pour cohérence
      ),
    );
  }
}
