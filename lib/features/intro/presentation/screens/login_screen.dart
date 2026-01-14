import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/notification_service.dart';
import 'package:go_router/go_router.dart';

import 'package:elyf_groupe_app/core/auth/providers.dart';
import '../../../../features/administration/application/providers.dart'
    show
        adminRepositoryProvider,
        permissionServiceProvider,
        enterpriseRepositoryProvider;
import '../../../../features/administration/domain/repositories/enterprise_repository.dart';
import '../../../../features/administration/domain/entities/enterprise.dart';
import '../../../../core/tenant/tenant_provider.dart'
    show activeEnterpriseIdProvider, userAccessibleEnterprisesProvider;
import '../../../../core/auth/entities/enterprise_module_user.dart';
import '../../../../features/modules/presentation/screens/module_menu_screen.dart'
    show ModuleMenuScreen;

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
        developer.log(
          'Previous session cleaned: active enterprise cleared',
          name: 'login',
        );
      } catch (e) {
        developer.log(
          'Warning: Failed to clear active enterprise (continuing anyway): $e',
          name: 'login',
        );
        // Continuer même si le nettoyage échoue
      }

      final authController = ref.read(authControllerProvider);

      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Connexion avec Firebase Auth via le controller
      // Le service crée automatiquement le profil dans Firestore
      // et le premier admin si nécessaire
      final user = await authController.signIn(
        email: email,
        password: password,
      );

      if (!mounted) return;

      // Rafraîchir les providers de manière sécurisée
      // Note: On invalide seulement les providers essentiels pour éviter les erreurs
      // avec les providers qui dépendent de services non encore initialisés
      try {
        ref.invalidate(currentUserProvider);
        ref.invalidate(currentUserIdProvider);
        // Invalider les providers tenant pour forcer le recalcul des entreprises accessibles
        ref.invalidate(userAccessibleEnterprisesProvider);
        // Ne pas invalider usersProvider ici pour éviter les erreurs d'initialisation
        // Il sera rafraîchi automatiquement quand l'utilisateur accède à la page admin
      } catch (e) {
        developer.log('Error invalidating providers: $e', name: 'login');
        // Ne pas bloquer la redirection même en cas d'erreur d'invalidation
      }

      // Déterminer la route de redirection basée sur les permissions réelles
      // Si isAdmin → /admin
      // Sinon → chercher les rôles/permissions (EnterpriseModuleUser) et rediriger selon :
      //   - 1 seule entreprise + 1 seul module → redirection directe vers ce module
      //   - 1 seule entreprise + plusieurs modules → /modules (sélection)
      //   - plusieurs entreprises → /modules (sélection d'entreprise)
      developer.log(
        'Login: Determining redirect route for user ${user.id}, isAdmin: ${user.isAdmin}',
        name: 'login',
      );

      final redirectRoute = await _determineRedirectRoute(
        ref: ref,
        userId: user.id,
        isAdmin: user.isAdmin,
      );

      developer.log(
        'Login: Redirect route determined: $redirectRoute',
        name: 'login',
      );

      if (mounted) {
        context.go(redirectRoute);
      }
    } catch (e, stackTrace) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      // Logger l'erreur complète pour le debugging
      developer.log(
        'Login error',
        name: 'login',
        error: e,
        stackTrace: stackTrace,
      );

      // Afficher un message d'erreur plus clair
      String errorMessage = e.toString().replaceAll('Exception: ', '');

      // Améliorer les messages d'erreur spécifiques
      if (errorMessage.contains('Problème de connexion réseau') ||
          errorMessage.contains('mode hors ligne') ||
          errorMessage.contains('mode offline')) {
        // Message déjà amélioré par le contrôleur
        // Ne rien changer
      } else if (errorMessage.contains('unavailable') ||
          errorMessage.contains('unable to resolve') ||
          errorMessage.contains('no address associated')) {
        errorMessage =
            'Problème de connexion réseau. L\'application fonctionnera en mode hors ligne. '
            'Assurez-vous que votre appareil a accès à Internet pour synchroniser les données.';
      } else if ((errorMessage.contains('not initialized') ||
              errorMessage.contains('notinitialized')) &&
          (errorMessage.contains('FirebaseApp') ||
              errorMessage.contains('Firebase') ||
              errorMessage.contains('firebase core'))) {
        errorMessage =
            'Firebase n\'est pas initialisé. Veuillez redémarrer l\'application complètement (pas juste hot reload).';
      } else if (errorMessage.contains('network') ||
          errorMessage.contains('internet') ||
          errorMessage.contains('connection')) {
        errorMessage =
            'Problème de connexion réseau. L\'application fonctionnera en mode hors ligne. '
            'Vérifiez votre connexion internet pour la synchronisation.';
      } else if (errorMessage.contains('user-not-found')) {
        errorMessage =
            'Aucun compte trouvé avec cet email. Vérifiez que l\'utilisateur existe dans Firebase Console.';
      } else if (errorMessage.contains('wrong-password') ||
          errorMessage.contains('invalid-credential')) {
        errorMessage = 'Mot de passe incorrect.';
      } else if (errorMessage.contains('invalid-email')) {
        errorMessage = 'Format d\'email invalide.';
      }

      NotificationService.showError(
        context,
        'Erreur de connexion: $errorMessage',
      );
    }
  }

  /// Détermine la route de redirection basée sur les permissions réelles de l'utilisateur.
  ///
  /// Logique de redirection :
  /// 1. Si isAdmin == true → rediriger vers /admin
  /// 2. Sinon (isAdmin == false) → chercher les rôles/permissions (EnterpriseModuleUser) :
  ///    - Si 1 seule entreprise + 1 seul module → redirection directe vers ce module
  ///    - Si 1 seule entreprise + plusieurs modules → /modules (page de sélection)
  ///    - Si plusieurs entreprises → /modules (page de sélection d'entreprise)
  ///    - Si aucun accès → /modules (affichera un message d'erreur)
  Future<String> _determineRedirectRoute({
    required WidgetRef ref,
    required String userId,
    required bool isAdmin,
  }) async {
    // Étape 1 : Si admin, rediriger directement vers /admin (pas de vérification des rôles)
    if (isAdmin) {
      return '/admin';
    }

    // Étape 2 : Si pas admin, chercher les rôles/permissions (EnterpriseModuleUser)
    developer.log(
      'Redirect: Starting route determination',
      name: 'login.redirect',
    );

    try {
      // Récupérer les repositories
      final adminRepo = ref.read(adminRepositoryProvider);
      final enterpriseRepo = ref.read(enterpriseRepositoryProvider);

      // Récupérer tous les accès de l'utilisateur
      final userAccesses = await adminRepo.getUserEnterpriseModuleUsers(userId);
      developer.log(
        'Redirect: Found ${userAccesses.length} total access(es) for user: ${userAccesses.map((a) => '${a.enterpriseId}/${a.moduleId}(isActive:${a.isActive})').join(", ")}',
        name: 'login.redirect',
      );

      final activeAccesses = userAccesses
          .where((access) => access.isActive)
          .toList();

      developer.log(
        'Redirect: Found ${activeAccesses.length} active access(es)',
        name: 'login.redirect',
      );

      if (activeAccesses.isEmpty) {
        developer.log(
          'Redirect: No active accesses, redirecting to /modules',
          name: 'login.redirect',
        );
        // Aucun accès → rediriger vers /modules (qui affichera un message d'erreur)
        return '/modules';
      }

      // Récupérer les entreprises uniques accessibles
      final enterpriseIds = activeAccesses
          .map((access) => access.enterpriseId)
          .toSet()
          .toList();
      developer.log(
        'Redirect: Found ${enterpriseIds.length} unique enterprise ID(s): $enterpriseIds',
        name: 'login.redirect',
      );

      final allEnterprises = await enterpriseRepo.getAllEnterprises();
      final accessibleEnterprises = allEnterprises
          .where(
            (enterprise) =>
                enterpriseIds.contains(enterprise.id) && enterprise.isActive,
          )
          .toList();

      developer.log(
        'Redirect: Found ${accessibleEnterprises.length} accessible enterprise(s)',
        name: 'login.redirect',
      );

      if (accessibleEnterprises.isEmpty) {
        developer.log(
          'Redirect: No accessible enterprises, redirecting to /modules',
          name: 'login.redirect',
        );
        return '/modules';
      }

      // Si plusieurs entreprises → /modules (pour sélectionner)
      if (accessibleEnterprises.length > 1) {
        developer.log(
          'Redirect: Multiple enterprises (${accessibleEnterprises.length}), redirecting to /modules',
          name: 'login.redirect',
        );
        return '/modules';
      }

      // Une seule entreprise → sélectionner automatiquement
      final singleEnterprise = accessibleEnterprises.first;
      // Utiliser le notifier du provider pour mettre à jour à la fois SharedPreferences ET le state
      final notifier = ref.read(activeEnterpriseIdProvider.notifier);
      await notifier.setActiveEnterpriseId(singleEnterprise.id);

      // Récupérer les modules accessibles pour cette entreprise (sans vérification détaillée des permissions)
      final enterpriseModules = activeAccesses
          .where((access) => access.enterpriseId == singleEnterprise.id)
          .map((access) => access.moduleId)
          .toSet()
          .toList();

      developer.log(
        'Redirect: Found ${enterpriseModules.length} module(s) for enterprise ${singleEnterprise.id}: $enterpriseModules',
        name: 'login.redirect',
      );

      if (enterpriseModules.isEmpty) {
        return '/modules';
      }

      // Si 1 seul module → rediriger directement vers ce module
      if (enterpriseModules.length == 1) {
        final moduleId = enterpriseModules.first;
        // Mapping des IDs de modules vers les routes
        const moduleRoutes = {
          'eau_minerale': '/modules/eau_sachet',
          'gaz': '/modules/gaz',
          'orange_money': '/modules/orange_money',
          'immobilier': '/modules/immobilier',
          'boutique': '/modules/boutique',
        };
        final route = moduleRoutes[moduleId];
        return route ?? '/modules';
      }

      // Plusieurs modules → /modules (pour sélectionner)
      return '/modules';
    } catch (e, stackTrace) {
      developer.log(
        'Error determining redirect route: $e',
        name: 'login.redirect',
        error: e,
        stackTrace: stackTrace,
      );
      // En cas d'erreur, rediriger vers /modules par défaut
      return '/modules';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          _AnimatedLoginBackground(
            animation: _backgroundAnimation,
            colors: colors,
          ),
          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: AnimatedBuilder(
                animation: _entryController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 40),
                          // Logo/Icon
                          _AnimatedLogo(colors: colors),
                          const SizedBox(height: 32),
                          // Title
                          Text(
                            'Connexion Elyf',
                            textAlign: TextAlign.center,
                            style: textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Subtitle
                          Text(
                            'Connectez-vous avec votre email professionnel pour accéder aux modules.',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyLarge?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 48),
                          // Form
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                _AnimatedFormField(
                                  controller: _emailController,
                                  focusNode: _emailFocusNode,
                                  label: 'Email professionnel',
                                  icon: Icons.email_outlined,
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
                                  icon: Icons.lock_outline,
                                  obscureText: _obscurePassword,
                                  delay: 0.3,
                                  animation: _fadeAnimation,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
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
                                const SizedBox(height: 32),
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
                  );
                },
              ),
            ),
          ),
        ],
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
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.layers,
              size: 40,
              color: colors.onPrimaryContainer,
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
          validator: validator,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            suffixIcon: suffixIcon,
            filled: true,
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
    return AnimatedBuilder(
      animation: scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: scaleAnimation.value,
          child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        );
      },
    );
  }
}

class _AnimatedLoginBackground extends StatelessWidget {
  const _AnimatedLoginBackground({
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
          painter: _LoginBackgroundPainter(
            progress: animation.value,
            colors: colors,
          ),
        );
      },
    );
  }
}

class _LoginBackgroundPainter extends CustomPainter {
  _LoginBackgroundPainter({required this.progress, required this.colors});

  final double progress;
  final ColorScheme colors;

  @override
  void paint(Canvas canvas, Size size) {
    // Gradient background
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        colors.primary,
        colors.primaryContainer,
        colors.secondaryContainer,
      ],
    );
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);

    // Animated circles
    final circlePaint = Paint()
      ..color = colors.onPrimary.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 3; i++) {
      final radius = 100.0 + (i * 80.0);
      final x =
          size.width * (0.2 + i * 0.3) +
          math.sin(progress * 2 * math.pi + i) * 30;
      final y =
          size.height * (0.3 + i * 0.2) +
          math.cos(progress * 2 * math.pi + i) * 30;

      canvas.drawCircle(
        Offset(x, y),
        radius * (0.8 + math.sin(progress * 2 * math.pi + i) * 0.2),
        circlePaint,
      );
    }

    // Animated geometric shapes
    final shapePaint = Paint()
      ..color = colors.onPrimary.withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 4; i++) {
      final angle = progress * 2 * math.pi + (i * math.pi / 2);
      final centerX = size.width * 0.5 + math.cos(angle) * 150;
      final centerY = size.height * 0.5 + math.sin(angle) * 150;

      final path = Path();
      final sides = 6;
      for (int j = 0; j < sides; j++) {
        final angle2 = (j * 2 * math.pi / sides) + angle;
        final x = centerX + math.cos(angle2) * 40;
        final y = centerY + math.sin(angle2) * 40;
        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, shapePaint);
    }
  }

  @override
  bool shouldRepaint(_LoginBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
