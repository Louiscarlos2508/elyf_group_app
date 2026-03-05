import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import '../../../../core/logging/app_logger.dart';

import '../../../../core/session/session_manager.dart';
import '../../../../core/session/session_state.dart';
import '../../../../core/auth/entities/app_user.dart';
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

    // Supprimer le splash screen natif dès que Flutter est prêt
    developer.log('Removing native splash from SplashScreen.initState', name: 'splash');
    FlutterNativeSplash.remove();

    // Logo animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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

    // Text animation
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _textFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    // Glow/pulse animation
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Wave animation
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    // Start animations
    _logoController.forward().then((_) {
      if (mounted) _textController.forward();
    });
  }

  /// Traiter le changement d'état de la session
  void _processState(SessionState state) {
    if (_navigated) return;
    
    if (state is AuthenticatedSession) {
      _navigated = true;
      _handleNavigation(state.user);
    } else if (state is UnauthenticatedSession) {
      _navigated = true;
      _handleNavigation(null);
    } else if (state is SessionError) {
      _navigated = true;
      AppLogger.error('Session error on splash: ${state.message}', name: 'splash');
      context.go('/login');
    }
  }

  /// Navigate to the appropriate screen based on authentication status
  Future<void> _handleNavigation(AppUser? user) async {
    if (!mounted) return;
    
    developer.log('Reactive navigation: user=${user?.email ?? "null"}', name: 'splash');
    
    if (user != null) {
      context.go('/modules');
    } else {
      final isOnboardingCompleted =
          await ref.read(onboardingServiceProvider).isCompleted();
      
      if (!mounted) return;
      
      if (isOnboardingCompleted) {
        context.go('/login');
      } else {
        context.go('/onboarding');
      }
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

  bool _navigated = false;

  @override
  Widget build(BuildContext context) {
    // Écouter l'état de la session de manière réactive
    ref.listen<SessionState>(sessionManagerProvider, (previous, next) {
      _processState(next);
    });

    // Vérifier l'état initial une seule fois après la première frame
    if (!_navigated) {
       final initialState = ref.read(sessionManagerProvider);
       if (initialState is AuthenticatedSession || initialState is UnauthenticatedSession) {
         WidgetsBinding.instance.addPostFrameCallback((_) => _processState(initialState));
       }
    }

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
                              blurRadius: 30 * _glowAnimation.value,
                              spreadRadius: 5 * _glowAnimation.value,
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
                  const SizedBox(height: 40),
                  // Animated ELYF text
                  _AnimatedElyfText(
                    fadeAnimation: _textFade,
                    glowAnimation: _glowAnimation,
                    colors: colors,
                    textTheme: textTheme,
                  ),
                  const SizedBox(height: 12),
                  // Subtitle
                  Opacity(
                    opacity: _textFade.value * 0.8,
                    child: Text(
                      'GROUPE ELYF',
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.7),
                        letterSpacing: 6.0,
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
          fontSize: 72, // Taille légèrement plus équilibrée
          letterSpacing: 4,
          height: 1.0,
          shadows: [
            Shadow(
              color: colors.primary.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
      ),
    );
  }
}
