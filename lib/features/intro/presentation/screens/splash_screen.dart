import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/providers.dart';
import '../../application/onboarding_service.dart';
import '../../../../shared/presentation/widgets/elyf_ui/atoms/elyf_background.dart';

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
  Future<void> _navigateToNextScreen() async {
    try {
      // Wait for the authentication state to be ready
      final user = await ref.read(currentUserProvider.future);
      
      if (!mounted) return;
      
      if (user != null) {
        // User is authenticated, go to modules
        context.go('/modules');
      } else {
        // User is not authenticated, check onboarding status
        final isOnboardingCompleted = 
            await ref.read(onboardingServiceProvider).isCompleted();
        
        if (!mounted) return;
        
        if (isOnboardingCompleted) {
          context.go('/login');
        } else {
          context.go('/onboarding');
        }
      }
    } catch (error) {
      // On error, go to login
      if (mounted) context.go('/login');
    }
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
      body: ElyfBackground(
        child: Center(
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
                   // Animated logo container
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
                              color: colors.primary.withValues(
                                alpha: _glowAnimation.value * 0.4,
                              ),
                              blurRadius: 40 * _glowAnimation.value,
                              spreadRadius: 10 * _glowAnimation.value,
                              offset: const Offset(0, 10),
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
                  // Animated ELYF text (Premium Typography)
                  _AnimatedElyfText(
                    fadeAnimation: _textFade,
                    glowAnimation: _glowAnimation,
                    colors: colors,
                    textTheme: textTheme,
                  ),
                  const SizedBox(height: 16),
                  // Subtitle (Premium Tracking)
                  Opacity(
                    opacity: _textFade.value * 0.8,
                    child: Text(
                      'GROUPE ELYF',
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.7),
                        letterSpacing: 8.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
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
    return FadeTransition(
      opacity: fadeAnimation,
      child: Text(
        'ELYF',
        style: textTheme.displayLarge?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w900,
          fontSize: 84,
          letterSpacing: 4,
          height: 1.0,
          shadows: [
            Shadow(
              color: colors.primary.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
      ),
    );
  }
}
