import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import 'package:flutter/services.dart';

/// Widget pour le champ de caution avec choix entre montant fixe ou nombre de mois.
class DepositField extends StatefulWidget {
  const DepositField({
    super.key,
    required this.depositController,
    required this.depositInMonthsController,
    required this.monthlyRent,
    this.initialDeposit,
    this.initialDepositInMonths,
  });

  final TextEditingController depositController;
  final TextEditingController depositInMonthsController;
  final int? monthlyRent;
  final int? initialDeposit;
  final int? initialDepositInMonths;

  @override
  State<DepositField> createState() => _DepositFieldState();
}

class _DepositFieldState extends State<DepositField> {
  bool _isInMonths = false;

  @override
  void initState() {
    super.initState();
    _isInMonths = widget.initialDepositInMonths != null;
    if (widget.initialDeposit != null) {
      widget.depositController.text = widget.initialDeposit.toString();
    }
    if (widget.initialDepositInMonths != null) {
      widget.depositInMonthsController.text = widget.initialDepositInMonths
          .toString();
      _updateDepositFromMonths();
    }
  }

  void _updateDepositFromMonths() {
    if (_isInMonths && widget.monthlyRent != null) {
      final months = int.tryParse(widget.depositInMonthsController.text);
      if (months != null && months > 0) {
        final calculated = widget.monthlyRent! * months;
        widget.depositController.text = calculated.toString();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Montant fixe'),
                    icon: Icon(Icons.attach_money, size: 18),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('En mois'),
                    icon: Icon(Icons.calendar_month, size: 18),
                  ),
                ],
                selected: {_isInMonths},
                onSelectionChanged: (Set<bool> selection) {
                  setState(() {
                    _isInMonths = selection.first;
                    if (_isInMonths) {
                      widget.depositController.clear();
                      _updateDepositFromMonths();
                    } else {
                      widget.depositInMonthsController.clear();
                    }
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isInMonths)
          TextFormField(
            controller: widget.depositInMonthsController,
            decoration: InputDecoration(
              labelText: 'Caution (nombre de mois)',
              prefixIcon: const Icon(Icons.calendar_month),
              suffixText: widget.monthlyRent != null
                  ? '= ${CurrencyFormatter.formatFCFA(_calculateDeposit())} FCFA'
                  : null,
              helperText: widget.monthlyRent != null
                  ? '${widget.monthlyRent} FCFA × nombre de mois'
                  : 'Définir d\'abord le loyer mensuel',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) {
              _updateDepositFromMonths();
              setState(() {});
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Le nombre de mois est requis';
              }
              final months = int.tryParse(value);
              if (months == null || months <= 0) {
                return 'Nombre de mois invalide';
              }
              return null;
            },
          )
        else
          TextFormField(
            controller: widget.depositController,
            decoration: const InputDecoration(
              labelText: 'Caution (FCFA)',
              prefixIcon: Icon(Icons.security),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'La caution est requise';
              }
              final amount = int.tryParse(value);
              if (amount == null || amount < 0) {
                return 'Montant invalide';
              }
              return null;
            },
          ),
      ],
    );
  }

  int _calculateDeposit() {
    if (!_isInMonths || widget.monthlyRent == null) return 0;
    final months = int.tryParse(widget.depositInMonthsController.text);
    if (months == null || months <= 0) return 0;
    return widget.monthlyRent! * months;
  }
}
