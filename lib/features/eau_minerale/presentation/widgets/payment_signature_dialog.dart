import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:elyf_groupe_app/shared.dart';


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
  final void Function(Uint8List signature, String? signerName) onPaid; // Updated callback

  @override
  State<PaymentSignatureDialog> createState() => _PaymentSignatureDialogState();
}

class _PaymentSignatureDialogState extends State<PaymentSignatureDialog> {
  final GlobalKey _signatureKey = GlobalKey();
  // Use nullable Offset to represent breaks in strokes
  final List<Offset?> _points = [];
  final TextEditingController _signerNameController = TextEditingController();
  
  @override
  void dispose() {
    _signerNameController.dispose();
    super.dispose();
  }

  void _addPoint(Offset? point) {
    setState(() {
      _points.add(point);
    });
  }

  void _clearSignature() {
    setState(() {
      _points.clear();
    });
  }

  Future<Uint8List?> _captureSignature() async {
    try {
      final RenderRepaintBoundary boundary =
          _signatureKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      // Increase pixelRatio for better quality
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
    // Check if there is at least one valid point
    if (_points.where((p) => p != null).isEmpty) {
      NotificationService.showError(
        context,
        'Veuillez signer avant de valider',
      );
      return;
    }

    final signature = await _captureSignature();
    if (!mounted) return;
    if (signature != null) {
      widget.onPaid(signature, _signerNameController.text.trim().isEmpty ? null : _signerNameController.text.trim());
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
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: Container(
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
                          CurrencyFormatter.formatFCFA(widget.amount),
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
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _signerNameController,
            decoration: const InputDecoration(
              labelText: 'Nom du signataire (Optionnel)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
              hintText: 'Qui signe ?',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
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
              borderRadius: BorderRadius.circular(12),
              color: Colors.white, // Always white for signing (like paper)
            ),
            clipBehavior: Clip.hardEdge,
            child: RepaintBoundary(
              key: _signatureKey,
              child: Builder(
                builder: (context) {
                  return Listener(
                    onPointerDown: (event) {
                      final renderBox = context.findRenderObject() as RenderBox;
                      final localPosition = renderBox.globalToLocal(event.position);
                      _addPoint(localPosition);
                    },
                    onPointerMove: (event) {
                      final renderBox = context.findRenderObject() as RenderBox;
                      final localPosition = renderBox.globalToLocal(event.position);
                      _addPoint(localPosition);
                    },
                    onPointerUp: (event) {
                      _addPoint(null);
                    },
                    onPointerCancel: (event) {
                      _addPoint(null);
                    },
                    child: CustomPaint(
                      painter: _SignaturePainter(
                        _points, 
                        Colors.black, // Always black ink
                        Colors.white, // Always white background for capture
                      ),
                      size: Size.infinite,
                    ),
                  );
                }
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Signez à l\'intérieur du cadre',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
              TextButton.icon(
                onPressed: _clearSignature,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Effacer'),
              ),
            ],
          ),
        ],
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
  _SignaturePainter(this.points, this.inkColor, this.backgroundColor);

  final List<Offset?> points;
  final Color inkColor;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Fill background so capture is opaque even if captured separately
    final bgPaint = Paint()..color = backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final paint = Paint()
      ..color = inkColor
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      } else if (points[i] != null && points[i + 1] == null) {
        // Draw a dot for single points
        canvas.drawPoints(ui.PointMode.points, [points[i]!], paint);
      }
    }
    // Handle last point if it's a dot
    if (points.isNotEmpty && points.last != null) {
       canvas.drawPoints(ui.PointMode.points, [points.last!], paint);
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter oldDelegate) {
    return true; // Simple and reliable during interactions
  }
}
