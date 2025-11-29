import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated loading screen for module initialization.
/// Displays module name with animated effects while data loads.
class ModuleLoadingAnimation extends StatefulWidget {
  const ModuleLoadingAnimation({
    super.key,
    required this.moduleName,
    required this.moduleIcon,
    this.message,
  });

  final String moduleName;
  final IconData moduleIcon;
  final String? message;

  @override
  State<ModuleLoadingAnimation> createState() =>
      _ModuleLoadingAnimationState();
}

class _ModuleLoadingAnimationState extends State<ModuleLoadingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late AnimationController _textController;
  late AnimationController _glowController;
  late AnimationController _particleController;

  late Animation<double> _iconScale;
  late Animation<double> _iconRotation;
  late Animation<double> _textFade;
  late Animation<double> _textSlide;
  late Animation<double> _glowAnimation;
  late Animation<double> _particleAnimation;

  @override
  void initState() {
    super.initState();

    // Icon animation
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _iconScale = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: Curves.easeInOut,
      ),
    );
    _iconRotation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: Curves.easeInOut,
      ),
    );

    // Text animation
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _textFade = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeInOut,
      ),
    );
    _textSlide = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeInOut,
      ),
    );

    // Glow animation
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );

    // Particle animation
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _particleController,
        curve: Curves.linear,
      ),
    );
  }

  @override
  void dispose() {
    _iconController.dispose();
    _textController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Stack(
        children: [
          // Animated background particles
          _AnimatedParticles(
            animation: _particleAnimation,
            colors: colors,
          ),
          // Main content
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _iconController,
                _textController,
                _glowController,
              ]),
              builder: (context, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated icon
                    Transform.scale(
                      scale: _iconScale.value,
                      child: Transform.rotate(
                        angle: _iconRotation.value * math.pi,
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: colors.primary.withValues(
                                  alpha: _glowAnimation.value * 0.4,
                                ),
                                blurRadius: 40 * _glowAnimation.value,
                                spreadRadius: 10 * _glowAnimation.value,
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.moduleIcon,
                            size: 64,
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Module name
                    Transform.translate(
                      offset: Offset(0, _textSlide.value),
                      child: Opacity(
                        opacity: _textFade.value,
                        child: Text(
                          widget.moduleName,
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Loading indicator
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colors.primary,
                        ),
                      ),
                    ),
                    if (widget.message != null) ...[
                      const SizedBox(height: 24),
                      Text(
                        widget.message!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedParticles extends StatelessWidget {
  const _AnimatedParticles({
    required this.animation,
    required this.colors,
  });

  final Animation<double> animation;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _ParticlePainter(
            progress: animation.value,
            color: colors.primary.withValues(alpha: 0.1),
          ),
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw floating particles
    for (int i = 0; i < 8; i++) {
      final angle = (progress * 2 * math.pi) + (i * math.pi / 4);
      final radius = 80.0 + (i * 20.0);
      final x = size.width / 2 + math.cos(angle) * radius;
      final y = size.height / 2 + math.sin(angle) * radius;
      final particleSize = 4.0 + (math.sin(progress * 2 * math.pi + i) * 2);

      canvas.drawCircle(
        Offset(x, y),
        particleSize,
        paint,
      );
    }

    // Draw connecting lines
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    for (int i = 0; i < 8; i++) {
      final angle1 = (progress * 2 * math.pi) + (i * math.pi / 4);
      final angle2 = (progress * 2 * math.pi) + ((i + 1) * math.pi / 4);
      final radius = 100.0;
      final x1 = size.width / 2 + math.cos(angle1) * radius;
      final y1 = size.height / 2 + math.sin(angle1) * radius;
      final x2 = size.width / 2 + math.cos(angle2) * radius;
      final y2 = size.height / 2 + math.sin(angle2) * radius;

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), linePaint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

