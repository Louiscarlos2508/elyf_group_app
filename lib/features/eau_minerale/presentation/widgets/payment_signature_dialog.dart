import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/notification_service.dart';

/// Dialog pour enregistrer une signature numérique après paiement.
class PaymentSignatureDialog extends StatefulWidget {
  const PaymentSignatureDialog({
    super.key,
    required this.workerName,
    required this.amount,
    this.daysWorked,
    this.week,
    this.period,
    required this.onPaid,
  });

  final String workerName;
  final int amount;
  final int? daysWorked; // Optionnel (pour salaire mensuel)
  final DateTime? week; // Optionnel (pour salaire mensuel)
  final String? period; // Optionnel (pour salaire mensuel, ex: "janvier 2024")
  final ValueChanged<Uint8List> onPaid;

  @override
  State<PaymentSignatureDialog> createState() => _PaymentSignatureDialogState();
}

class _PaymentSignatureDialogState extends State<PaymentSignatureDialog> {
  final GlobalKey _signatureKey = GlobalKey();
  final List<Offset> _points = [];
  bool _hasSignature = false;

  void _addPoint(Offset point) {
    setState(() {
      _points.add(point);
      _hasSignature = true;
    });
  }

  void _clearSignature() {
    setState(() {
      _points.clear();
      _hasSignature = false;
    });
  }

  Future<Uint8List?> _captureSignature() async {
    try {
      final RenderRepaintBoundary boundary =
          _signatureKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  Future<void> _submit() async {
    if (!_hasSignature) {
      NotificationService.showError(
        context,
        'Veuillez signer avant de valider',
      );
      return;
    }

    final signature = await _captureSignature();
    if (!mounted) return;
    if (signature != null) {
      widget.onPaid(signature);
    } else {
      NotificationService.showError(
        context,
        'Erreur lors de la capture de la signature',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Signature de paiement'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Informations du paiement
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.workerName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (widget.daysWorked != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Jours travaillés:',
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          '${widget.daysWorked} jour(s)',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  if (widget.period != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Période:', style: theme.textTheme.bodyMedium),
                        Text(
                          widget.period!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Montant:', style: theme.textTheme.bodyMedium),
                      Text(
                        '${widget.amount} CFA',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Signature du bénéficiaire',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: RepaintBoundary(
                key: _signatureKey,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    final RenderBox box =
                        context.findRenderObject() as RenderBox;
                    final localPosition = box.globalToLocal(
                      details.globalPosition,
                    );
                    _addPoint(localPosition);
                  },
                  onPanEnd: (details) {
                    _addPoint(const Offset(-1, -1)); // Marqueur de fin de trait
                  },
                  child: CustomPaint(
                    painter: _SignaturePainter(_points),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _clearSignature,
                  child: const Text('Effacer'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Veuillez signer dans la zone ci-dessus pour confirmer le paiement.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Valider le paiement'),
        ),
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter(this.points);

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i].dx < 0 || points[i + 1].dx < 0) {
        continue; // Ignorer les marqueurs de fin de trait
      }
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
