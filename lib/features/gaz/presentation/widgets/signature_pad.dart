
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/shared.dart';

class SignaturePad extends StatefulWidget {
  const SignaturePad({
    super.key,
    required this.onSign,
    this.hint = 'Signez ici',
  });

  final Function(String base64) onSign;
  final String hint;

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  final List<Offset?> _points = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                RenderBox renderBox = context.findRenderObject() as RenderBox;
                _points.add(renderBox.globalToLocal(details.globalPosition));
              });
            },
            onPanEnd: (details) => _points.add(null),
            child: CustomPaint(
              painter: _SignaturePainter(_points),
              size: Size.infinite,
              child: _points.isEmpty
                  ? Center(
                      child: Text(
                        widget.hint,
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => setState(() => _points.clear()),
              child: const Text('Effacer'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _points.isEmpty ? null : _saveSignature,
              child: const Text('Confirmer Signature'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _saveSignature() async {
    // Generate base64 from points (Simplified for this task)
    // In a real app we would use a library or ui.PictureRecorder
    // For now, we will return a dummy base64 or a structured string representing the points
    // since we don't have a direct way to export ui.Image to base64 easily without a library in a one-shot tool.
    // Actually, I can use ui.PictureRecorder.
    
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final painter = _SignaturePainter(_points);
    painter.paint(canvas, const Size(400, 200));
    final picture = recorder.endRecording();
    final img = await picture.toImage(400, 200);
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
    
    if (pngBytes != null) {
      final base64 = base64Encode(pngBytes.buffer.asUint8List());
      widget.onSign(base64);
    }
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter(this.points);
  final List<Offset?> points;

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter oldDelegate) => true;
}
