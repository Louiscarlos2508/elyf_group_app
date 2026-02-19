import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';

import '../../domain/entities/sale.dart';
import 'invoice_print/invoice_print_service.dart';

/// Helper widgets for sales table.
class SalesTableHelpers {
  static Widget buildStatusChip(BuildContext context, Sale sale) {
    final theme = Theme.of(context);
    final isPaid = sale.isFullyPaid;
    final isCredit = sale.isCredit;

    String statusText;
    Color statusColor;

    if (sale.status == SaleStatus.voided) {
      statusText = 'Annulée';
      statusColor = Colors.red;
    } else if (isPaid) {
      statusText = 'Payé';
      statusColor = Colors.green;
    } else if (isCredit) {
      statusText = 'Crédit';
      statusColor = Colors.orange;
    } else {
      statusText = 'En attente';
      statusColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        statusText,
        style: theme.textTheme.labelSmall?.copyWith(
          color: statusColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static Widget buildActionButtons(
    BuildContext context,
    Sale sale,
    void Function(Sale sale, String action)? onActionTap,
  ) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz,
        color: theme.colorScheme.primary,
      ),
      tooltip: 'Actions',
      onSelected: (value) async {
        if (value == 'print') {
          _showPrintOptions(context, sale);
        } else {
          onActionTap?.call(sale, value);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'view',
          child: ListTile(
            leading: const Icon(Icons.visibility_outlined, size: 20),
            title: const Text('Voir les détails'),
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            dense: true,
          ),
        ),
        PopupMenuItem(
          value: 'print',
          enabled: sale.status != SaleStatus.voided,
          child: ListTile(
            leading: const Icon(Icons.print_outlined, size: 20),
            title: const Text('Imprimer Facture'),
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            dense: true,
          ),
        ),
        PopupMenuItem(
          value: 'void',
          enabled: sale.status != SaleStatus.voided,
          child: ListTile(
            leading: Icon(
              Icons.cancel_outlined,
              size: 20,
              color: sale.status != SaleStatus.voided ? Colors.red : null,
            ),
            title: Text(
              'Annuler la vente',
              style: TextStyle(
                color: sale.status != SaleStatus.voided ? Colors.red : null,
              ),
            ),
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            dense: true,
          ),
        ),
      ],
    );
  }

  static Future<void> _showPrintOptions(BuildContext context, Sale sale) async {
    // We basically trigger the same logic as EauMineralePrintButton but without needing the widget
    showModalBottomSheet(
      context: context,
      builder: (context) => _PrintOptionsSheet(sale: sale),
    );
  }
}

class _PrintOptionsSheet extends StatefulWidget {
  final Sale sale;
  const _PrintOptionsSheet({required this.sale});

  @override
  State<_PrintOptionsSheet> createState() => _PrintOptionsSheetState();
}

class _PrintOptionsSheetState extends State<_PrintOptionsSheet> {
  bool _isSunmiAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkSunmi();
  }

  Future<void> _checkSunmi() async {
    final available = await EauMineraleInvoiceService.instance.isSunmiAvailable();
    if (mounted) setState(() => _isSunmiAvailable = available);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Options d\'impression',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: const Text('Générer PDF'),
            subtitle: const Text('Créer un fichier PDF'),
            onTap: () async {
              Navigator.pop(context);
              await _handlePrint('pdf');
            },
          ),
          if (_isSunmiAvailable)
            ListTile(
              leading: const Icon(Icons.print),
              title: const Text('Imprimer (Sunmi)'),
              subtitle: const Text('Imprimante thermique'),
              onTap: () async {
                Navigator.pop(context);
                await _handlePrint('sunmi');
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _handlePrint(String type) async {
    try {
      if (type == 'pdf') {
        final file = await EauMineraleInvoiceService.instance.generateSalePdf(widget.sale);
        await OpenFile.open(file.path);
      } else {
        await EauMineraleInvoiceService.instance.printSaleInvoice(widget.sale);
      }
    } catch (e) {
      debugPrint('Error printing: $e');
    }
  }
}
