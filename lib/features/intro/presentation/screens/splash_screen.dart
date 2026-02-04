import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/providers.dart';
import '../../application/onboarding_service.dart';

/// Animated splash screen with ELYF branding.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _glowController;
  late AnimationController _waveController;
  late Animation<double> _logoScale;
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
    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
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
        _navigateToNextScreen();
      }
    });
  }

  /// Navigate to the appropriate screen based on authentication status
  void _navigateToNextScreen() {
    ref.read(currentUserProvider).when(
      data: (user) async {
        if (user != null) {
          if (mounted) context.go('/modules');
        } else {
          // Check if onboarding is completed
          final isOnboardingCompleted = 
              await ref.read(onboardingServiceProvider).isCompleted();
          
          if (mounted) {
            if (isOnboardingCompleted) {
              context.go('/login');
            } else {
              context.go('/onboarding');
            }
          }
        }
      },
      loading: () async {
        // Fallback to onboarding if auth is taking too long
        if (mounted) context.go('/onboarding');
      },
      error: (error, stack) {
        if (mounted) context.go('/login');
      },
    );
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
          // Animated background blobs (White blobs on Primary for high contrast)
          _AnimatedSplashBackground(
            animation: _waveAnimation,
            colors: colors,
            useContrast: true,
          ),
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
                    // Animated logo container (White background for logo on Primary background)
                    Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(
                                  alpha: _glowAnimation.value * 0.4,
                                ),
                                blurRadius: 40 * _glowAnimation.value,
                                spreadRadius: 10 * _glowAnimation.value,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.business_rounded,
                            size: 80,
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 60),
                    // Animated ELYF text (White on Primary)
                    _AnimatedElyfText(
                      fadeAnimation: _textFade,
                      glowAnimation: _glowAnimation,
                      colors: colors,
                      textTheme: textTheme,
                      useContrast: true,
                    ),
                    const SizedBox(height: 16),
                    // Subtitle with fade
                    Opacity(
                      opacity: _textFade.value * 0.7,
                      child: Text(
                        'GROUPE ELYF',
                        style: textTheme.titleSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.6),
                          letterSpacing: 4.0,
                          fontWeight: FontWeight.bold,
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

class _AnimatedSplashBackground extends StatelessWidget {
  const _AnimatedSplashBackground({
    required this.animation,
    required this.colors,
    this.useContrast = false,
  });

  final Animation<double> animation;
  final ColorScheme colors;
  final bool useContrast;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _SplashBackgroundPainter(
            progress: animation.value,
            colors: colors,
            useContrast: useContrast,
          ),
        );
      },
    );
  }
}

class _SplashBackgroundPainter extends CustomPainter {
  _SplashBackgroundPainter({
    required this.progress,
    required this.colors,
    this.useContrast = false,
  });

  final double progress;
  final ColorScheme colors;
  final bool useContrast;

  @override
  void paint(Canvas canvas, Size size) {
    final bgColor = useContrast ? colors.primary : colors.surface;
    final blobColor = useContrast ? Colors.white : colors.primary;

    // Deep background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = bgColor,
    );

    // Soft animated blobs
    final blob1Center = Offset(
      size.width * 0.3 + math.sin(progress * 2 * math.pi) * 80,
      size.height * 0.3 + math.cos(progress * 2 * math.pi) * 80,
    );
    _drawBlob(canvas, blob1Center, size.width * 0.7, blobColor.withValues(alpha: 0.08));

    final blob2Center = Offset(
      size.width * 0.7 + math.cos(progress * 2 * math.pi) * 90,
      size.height * 0.7 + math.sin(progress * 2 * math.pi) * 90,
    );
    _drawBlob(canvas, blob2Center, size.width * 0.6, blobColor.withValues(alpha: 0.1));

    final blob3Center = Offset(
      size.width * 0.5 + math.sin(progress * 2 * math.pi * 0.5) * 120,
      size.height * 0.5 + math.cos(progress * 2 * math.pi * 0.5) * 120,
    );
    _drawBlob(canvas, blob3Center, size.width * 0.8, blobColor.withValues(alpha: 0.05));
  }

  void _drawBlob(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _SplashBackgroundPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.colors != colors ||
      oldDelegate.useContrast != useContrast;
}

class _AnimatedElyfText extends StatelessWidget {
  const _AnimatedElyfText({
    required this.fadeAnimation,
    required this.glowAnimation,
    required this.colors,
    required this.textTheme,
    this.useContrast = false,
  });

  final Animation<double> fadeAnimation;
  final Animation<double> glowAnimation;
  final ColorScheme colors;
  final TextTheme textTheme;
  final bool useContrast;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: Text(
        'ELYF',
        style: textTheme.displayLarge?.copyWith(
          color: useContrast ? Colors.white : colors.primary,
          fontWeight: FontWeight.w900,
          fontSize: 84,
          letterSpacing: 8,
          shadows: [
            Shadow(
              color: (useContrast ? Colors.white : colors.primary).withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
      ),
    );
  }
}
