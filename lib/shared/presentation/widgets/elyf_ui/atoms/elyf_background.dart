import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A premium animated mesh gradient background.
///
/// This widget creates a sophisticated, deep background by blending
/// the application's primary, secondary, and tertiary colors in a
/// slow-moving, organic fluid simulation.
///
/// It supports Glassmorphism by providing a rich, textured backdrop
/// that makes blurred overlays "pop".
class ElyfBackground extends StatefulWidget {
  const ElyfBackground({
    super.key,
    this.child,
    this.animate = true,
  });

  /// The content to display on top of the background.
  final Widget? child;

  /// Whether the background blobs should move.
  final bool animate;

  @override
  State<ElyfBackground> createState() => _ElyfBackgroundState();
}

class _ElyfBackgroundState extends State<ElyfBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 20)); // Slow, premium feeling

    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ElyfBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Use softer colors for dark mode, vibrant for light
    final primary = colors.primary.withValues(alpha: isDark ? 0.3 : 0.8);
    final secondary = colors.secondaryContainer.withValues(alpha: isDark ? 0.3 : 0.6);
    final tertiary = colors.tertiaryContainer.withValues(alpha: isDark ? 0.3 : 0.6);
    final background = theme.scaffoldBackgroundColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        // If we are in an unbounded vertical space (like a Sliver), 
        // we need to ensure we don't try to occupy infinite space.
        // If there's no child, we use a fallback height.
        // If there is a child, the Stack Fit will handle it, but 
        // we should still be careful with the painters.
        
        final Widget content = Stack(
          clipBehavior: Clip.antiAlias,
          children: [
            // Solid background base
            Positioned.fill(child: Container(color: background)),

            // Animated Mesh Gradient Painter
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _MeshGradientPainter(
                      progress: _controller.value,
                      primary: primary,
                      secondary: secondary,
                      tertiary: tertiary,
                    ),
                  );
                },
              ),
            ),

            // Content
            if (widget.child != null) widget.child!,
          ],
        );

        if (!constraints.hasBoundedHeight && widget.child == null) {
          return SizedBox(height: 400, child: content);
        }

        return content;
      },
    );
  }
}

class _MeshGradientPainter extends CustomPainter {
  _MeshGradientPainter({
    required this.progress,
    required this.primary,
    required this.secondary,
    required this.tertiary,
  });

  final double progress;
  final Color primary;
  final Color secondary;
  final Color tertiary;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    
    final w = size.width;
    // Check for infinite height and use a fallback (e.g. 500 or screen width)
    final h = size.height.isInfinite ? (w > 0 ? w : 500.0) : size.height;

    // Blob 1: Primary - Floating Top Left
    final blob1Pos = Offset(
      w * 0.2 + math.sin(progress * 2 * math.pi) * 50,
      h * 0.3 + math.cos(progress * 2 * math.pi) * 50,
    );
    _drawBlob(canvas, blob1Pos, w * 0.8, primary);

    // Blob 2: Secondary - Floating Bottom Right
    final blob2Pos = Offset(
      w * 0.8 + math.cos(progress * 2 * math.pi) * 60,
      h * 0.7 + math.sin(progress * 2 * math.pi) * 60,
    );
    _drawBlob(canvas, blob2Pos, w * 0.7, secondary);

    // Blob 3: Tertiary - Moving Center
    final blob3Pos = Offset(
      w * 0.5 + math.sin(progress * 2 * math.pi * 0.5) * 80,
      h * 0.5 + math.cos(progress * 2 * math.pi * 0.5) * 80,
    );
    _drawBlob(canvas, blob3Pos, w * 0.6, tertiary);
  }

  void _drawBlob(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color,
          color.withValues(alpha: 0.5),
          color.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _MeshGradientPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.primary != primary;
}
