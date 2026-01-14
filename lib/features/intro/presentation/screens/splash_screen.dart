import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Animated splash screen with ELYF branding.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _glowController;
  late AnimationController _waveController;
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _logoOpacity;
  late Animation<double> _textFade;
  late Animation<double> _glowAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();

    // Logo animation - longer and more dramatic
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );
    _logoRotation = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Text animation - longer stagger with more effects
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _textFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    // Glow/pulse animation (continuous)
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Wave animation for background effect
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _waveController, curve: Curves.linear));

    // Start animations in sequence
    _logoController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _textController.forward();
      });
    });

    // Navigate after all animations complete
    // Animation du logo: 2000ms + délai 300ms + animation texte: 2500ms = ~4800ms
    // On ajoute 2.5 secondes supplémentaires pour laisser le temps d'apprécier
    _timer = Timer(const Duration(milliseconds: 7000), () {
      if (mounted) {
        context.go('/onboarding');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _logoController.dispose();
    _textController.dispose();
    _glowController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.primary,
      body: Stack(
        children: [
          // Animated background waves
          _AnimatedBackground(waveAnimation: _waveAnimation, colors: colors),
          // Main content
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _logoController,
                _textController,
                _glowController,
              ]),
              builder: (context, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated logo container with more effects
                    Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Transform.rotate(
                          angle: _logoRotation.value * math.pi,
                          child: Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: colors.onPrimary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: colors.onPrimary.withValues(
                                    alpha: _glowAnimation.value * 0.6,
                                  ),
                                  blurRadius: 40 * _glowAnimation.value,
                                  spreadRadius: 15 * _glowAnimation.value,
                                ),
                                BoxShadow(
                                  color: colors.onPrimary.withValues(
                                    alpha: _glowAnimation.value * 0.3,
                                  ),
                                  blurRadius: 60 * _glowAnimation.value,
                                  spreadRadius: 20 * _glowAnimation.value,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.layers,
                              size: 72,
                              color: colors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Animated ELYF text with enhanced effects
                    _AnimatedElyfText(
                      fadeAnimation: _textFade,
                      glowAnimation: _glowAnimation,
                      colors: colors,
                      textTheme: textTheme,
                    ),
                    const SizedBox(height: 24),
                    // Subtitle with fade
                    Opacity(
                      opacity: _textFade.value * 0.9,
                      child: Text(
                        'Multi-entreprises, multi-modules',
                        style: textTheme.titleMedium?.copyWith(
                          color: colors.onPrimary.withValues(alpha: 0.85),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
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

class _AnimatedBackground extends StatelessWidget {
  const _AnimatedBackground({
    required this.waveAnimation,
    required this.colors,
  });

  final Animation<double> waveAnimation;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: waveAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _WavePainter(
            progress: waveAnimation.value,
            color: colors.onPrimary.withValues(alpha: 0.05),
          ),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = 30.0;
    final waveLength = size.width / 2;

    path.moveTo(0, size.height * 0.7);

    for (double x = 0; x <= size.width; x++) {
      final y =
          size.height * 0.7 +
          waveHeight *
              math.sin((x / waveLength + progress * 2 * math.pi) * 2 * math.pi);
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _AnimatedElyfText extends StatelessWidget {
  const _AnimatedElyfText({
    required this.fadeAnimation,
    required this.glowAnimation,
    required this.colors,
    required this.textTheme,
  });

  final Animation<double> fadeAnimation;
  final Animation<double> glowAnimation;
  final ColorScheme colors;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    const letters = ['E', 'L', 'Y', 'F'];
    const delays = [0.0, 0.15, 0.3, 0.45];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(letters.length, (index) {
        final delay = delays[index];

        final letterFade = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: fadeAnimation,
            curve: Interval(
              delay,
              math.min(delay + 0.4, 1.0),
              curve: Curves.easeOut,
            ),
          ),
        );

        final letterScale = Tween<double>(begin: 0.3, end: 1.0).animate(
          CurvedAnimation(
            parent: fadeAnimation,
            curve: Interval(
              delay,
              math.min(delay + 0.4, 1.0),
              curve: Curves.elasticOut,
            ),
          ),
        );

        final letterSlide = Tween<double>(begin: 50.0, end: 0.0).animate(
          CurvedAnimation(
            parent: fadeAnimation,
            curve: Interval(
              delay,
              math.min(delay + 0.4, 1.0),
              curve: Curves.easeOutCubic,
            ),
          ),
        );

        final letterRotation = Tween<double>(begin: 0.3, end: 0.0).animate(
          CurvedAnimation(
            parent: fadeAnimation,
            curve: Interval(
              delay,
              math.min(delay + 0.4, 1.0),
              curve: Curves.easeOutBack,
            ),
          ),
        );

        return AnimatedBuilder(
          animation: Listenable.merge([
            letterFade,
            letterScale,
            letterSlide,
            letterRotation,
            glowAnimation,
          ]),
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, letterSlide.value),
              child: Transform.rotate(
                angle: letterRotation.value,
                child: Transform.scale(
                  scale: letterScale.value,
                  child: Opacity(
                    opacity: letterFade.value,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colors.onPrimary,
                            colors.onPrimary.withValues(
                              alpha: 0.9 + (glowAnimation.value * 0.1),
                            ),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: colors.onPrimary.withValues(
                              alpha: glowAnimation.value * 0.4,
                            ),
                            blurRadius: 20 * glowAnimation.value,
                            spreadRadius: 3 * glowAnimation.value,
                          ),
                          BoxShadow(
                            color: colors.onPrimary.withValues(
                              alpha: glowAnimation.value * 0.2,
                            ),
                            blurRadius: 40 * glowAnimation.value,
                            spreadRadius: 5 * glowAnimation.value,
                          ),
                        ],
                      ),
                      child: Text(
                        letters[index],
                        style: textTheme.headlineLarge?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 56,
                          letterSpacing: 0,
                          shadows: [
                            Shadow(
                              color: colors.primary.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
