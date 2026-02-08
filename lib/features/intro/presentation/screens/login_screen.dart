import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/utils/notification_service.dart';

import '../../../../core/auth/providers.dart';
import '../../../../core/tenant/tenant_provider.dart'
    show activeEnterpriseIdProvider;
import '../../../../shared/presentation/widgets/elyf_ui/atoms/elyf_background.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _entryController;
  late AnimationController _backgroundController;
  late AnimationController _buttonController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _buttonScale;

  @override
  void initState() {
    super.initState();

    // Entry animations
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entryController,
            curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    // Background animation
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.linear),
    );

    // Button animation
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _buttonScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

    // Start entry animation
    _entryController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _entryController.dispose();
    _backgroundController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    _buttonController.forward().then((_) {
      _buttonController.reverse();
    });

    setState(() => _isLoading = true);

    try {
      // Nettoyer la session précédente (entreprise active) avant la connexion
      // pour éviter les problèmes de chargement infini avec une entreprise invalide
      try {
        final tenantNotifier = ref.read(activeEnterpriseIdProvider.notifier);
        await tenantNotifier.clearActiveEnterprise();
      } catch (_) {
        // Continuer même si le nettoyage échoue
      }

      final authController = ref.read(authControllerProvider);

      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Connexion avec Firebase Auth via le controller
      await authController.signIn(
        email: email,
        password: password,
      );

      // IMPORTANT: Invalider les providers pour forcer le routeur à re-évaluer
      // car ils ne sont pas automatiquement notifiés du changement manuel dans AuthService
      ref.invalidate(currentUserProvider);
      ref.invalidate(isAuthenticatedProvider);
      ref.invalidate(isAdminProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      NotificationService.showError(
        context,
        'Erreur de connexion: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: ElyfBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: AnimatedBuilder(
                animation: _entryController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo/Icon
                          _AnimatedLogo(colors: colors),
                          const SizedBox(height: 48),
                          // Glass(morphism) Card
                          ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: BackdropFilter(
                              filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                              child: Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  // White glass effect
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(32),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colors.shadow.withValues(alpha: 0.1),
                                      blurRadius: 40,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 20),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Bienvenue sur Elyf',
                                      textAlign: TextAlign.center,
                                      style: textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colors.primary, // Dark text on light glass
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Connectez-vous pour continuer',
                                      textAlign: TextAlign.center,
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colors.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 40),
                                    // Form
                                    Form(
                                      key: _formKey,
                                      child: Column(
                                        children: [
                                          _AnimatedFormField(
                                            controller: _emailController,
                                            focusNode: _emailFocusNode,
                                            label: 'Email professionnel',
                                            icon: Icons.alternate_email_rounded,
                                            keyboardType: TextInputType.emailAddress,
                                            delay: 0.2,
                                            animation: _fadeAnimation,
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Email requis';
                                              }
                                              if (!value.contains('@')) {
                                                return 'Email invalide';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 20),
                                          _AnimatedFormField(
                                            controller: _passwordController,
                                            focusNode: _passwordFocusNode,
                                            label: 'Mot de passe',
                                            icon: Icons.password_rounded,
                                            obscureText: _obscurePassword,
                                            delay: 0.3,
                                            animation: _fadeAnimation,
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscurePassword
                                                    ? Icons.visibility_outlined
                                                    : Icons.visibility_off_outlined,
                                                size: 20,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _obscurePassword = !_obscurePassword;
                                                });
                                              },
                                            ),
                                            validator: (value) {
                                              if (value == null || value.length < 6) {
                                                return '6 caractères minimum';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 40),
                                          // Login button
                                          _AnimatedLoginButton(
                                            onPressed: _isLoading ? null : _submit,
                                            isLoading: _isLoading,
                                            scaleAnimation: _buttonScale,
                                            buttonController: _buttonController,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          // Footer info
                          Text(
                            'Powered by Scalario',
                            textAlign: TextAlign.center,
                            style: textTheme.labelSmall?.copyWith(
                              color: colors.onSurface.withValues(alpha: 0.5),
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedLogo extends StatelessWidget {
  const _AnimatedLogo({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  colors.primary,
                  colors.primary.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 10,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.business_rounded,
              size: 50,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedFormField extends StatelessWidget {
  const _AnimatedFormField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.icon,
    required this.delay,
    required this.animation,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.validator,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final IconData icon;
  final double delay;
  final Animation<double> animation;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    final fieldFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: Interval(delay, delay + 0.3, curve: Curves.easeOut),
      ),
    );

    final fieldSlide =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: animation,
            curve: Interval(delay, delay + 0.3, curve: Curves.easeOutCubic),
          ),
        );

    return FadeTransition(
      opacity: fieldFade,
      child: SlideTransition(
        position: fieldSlide,
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: TextStyle(color: colors.onSurface, fontSize: 16),
          validator: validator,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: colors.onSurface.withValues(alpha: 0.6)),
            prefixIcon: Icon(icon, color: colors.primary.withValues(alpha: 0.7), size: 22),
            suffixIcon: suffixIcon,
            filled: true,
            // White background for inputs to ensure contrast on glass
            fillColor: Colors.white.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.transparent),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colors.error.withValues(alpha: 0.5)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colors.error, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedLoginButton extends StatelessWidget {
  const _AnimatedLoginButton({
    required this.onPressed,
    required this.isLoading,
    required this.scaleAnimation,
    required this.buttonController,
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final Animation<double> scaleAnimation;
  final AnimationController buttonController;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return AnimatedBuilder(
      animation: scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: scaleAnimation.value,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  colors.primary,
                  colors.primary.withValues(alpha: 0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Se connecter',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
