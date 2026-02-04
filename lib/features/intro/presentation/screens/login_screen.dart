import 'dart:developer' as developer;
import 'dart:ui' as ui;

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
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
        enterpriseRepositoryProvider;
import '../../../../core/tenant/tenant_provider.dart'
    show activeEnterpriseIdProvider, userAccessibleEnterprisesProvider;

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
      } catch (e, stackTrace) {
        final appException = ErrorHandler.instance.handleError(e, stackTrace);
        AppLogger.warning(
          'Error invalidating providers: ${appException.message}',
          name: 'login',
          error: e,
          stackTrace: stackTrace,
        );
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
      
      AppLogger.debug(
        'LOGIN REDIRECT: ${userAccesses.length} accès trouvés pour l\'utilisateur $userId',
        name: 'login.redirect',
      );
      for (final access in userAccesses) {
        AppLogger.debug(
          'LOGIN REDIRECT: Accès - enterpriseId=${access.enterpriseId}, moduleId=${access.moduleId}, isActive=${access.isActive}',
          name: 'login.redirect',
        );
      }
      
      developer.log(
        'Redirect: Found ${userAccesses.length} total access(es) for user: ${userAccesses.map((a) => '${a.enterpriseId}/${a.moduleId}(isActive:${a.isActive})').join(", ")}',
        name: 'login.redirect',
      );

      final activeAccesses = userAccesses
          .where((access) => access.isActive)
          .toList();

      AppLogger.debug(
        'LOGIN REDIRECT: ${activeAccesses.length} accès actifs',
        name: 'login.redirect',
      );
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
      
      AppLogger.debug(
        'LOGIN REDIRECT: ${enterpriseIds.length} IDs d\'entreprises uniques depuis EnterpriseModuleUser: ${enterpriseIds.join(", ")}',
        name: 'login.redirect',
      );
      developer.log(
        'Redirect: Found ${enterpriseIds.length} unique enterprise ID(s): $enterpriseIds',
        name: 'login.redirect',
      );

      final allEnterprises = await enterpriseRepo.getAllEnterprises();
      
      final posCount = allEnterprises.where((e) => e.description?.contains("Point de vente") ?? false).length;
      AppLogger.debug(
        'LOGIN REDIRECT: ${allEnterprises.length} entreprises récupérées au total (dont $posCount points de vente)',
        name: 'login.redirect',
      );
      AppLogger.debug(
        'LOGIN REDIRECT: IDs de toutes les entreprises: ${allEnterprises.map((e) => e.id).join(", ")}',
        name: 'login.redirect',
      );
      
      developer.log(
        'Redirect: ${allEnterprises.length} entreprises récupérées au total (dont $posCount points de vente)',
        name: 'login.redirect',
      );
      
      final accessibleEnterprises = allEnterprises
          .where(
            (enterprise) =>
                enterpriseIds.contains(enterprise.id) && enterprise.isActive,
          )
          .toList();

      AppLogger.debug(
        'LOGIN REDIRECT: ${accessibleEnterprises.length} entreprises accessibles après filtrage',
        name: 'login.redirect',
      );
      AppLogger.debug(
        'LOGIN REDIRECT: IDs des entreprises accessibles: ${accessibleEnterprises.map((e) => e.id).join(", ")}',
        name: 'login.redirect',
      );
      
      // Log des entreprises non trouvées
      final notFoundIds = enterpriseIds.where((id) => !allEnterprises.any((e) => e.id == id)).toList();
      if (notFoundIds.isNotEmpty) {
        AppLogger.warning(
          'LOGIN REDIRECT: IDs d\'entreprises non trouvées dans getAllEnterprises(): ${notFoundIds.join(", ")}',
          name: 'login.redirect',
        );
      }
      
      developer.log(
        'Redirect: Found ${accessibleEnterprises.length} accessible enterprise(s) (IDs: ${accessibleEnterprises.map((e) => e.id).join(", ")})',
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
          Center(
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
                            // Glassmorphism Card
                            ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: BackdropFilter(
                                filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                                child: Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: colors.surface.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(32),
                                    border: Border.all(
                                      color: colors.onSurface.withValues(alpha: 0.1),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 40,
                                        spreadRadius: 0,
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
                                          color: colors.onSurface,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Connectez-vous pour continuer',
                                        textAlign: TextAlign.center,
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: colors.onSurfaceVariant.withValues(alpha: 0.8),
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
                                color: colors.onSurface.withValues(alpha: 0.4),
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
          style: TextStyle(color: colors.onSurface, fontSize: 15),
          validator: validator,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: colors.onSurface.withValues(alpha: 0.6)),
            prefixIcon: Icon(icon, color: colors.primary.withValues(alpha: 0.7), size: 22),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: colors.surface.withValues(alpha: 0.05),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colors.onSurface.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colors.primary.withValues(alpha: 0.5), width: 2),
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
            height: 60,
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
                        fontSize: 18,
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
    // Deep background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = colors.surface,
    );

    // Soft animated blobs
    final blob1Center = Offset(
      size.width * 0.2 + math.sin(progress * 2 * math.pi) * 50,
      size.height * 0.2 + math.cos(progress * 2 * math.pi) * 50,
    );
    _drawBlob(canvas, blob1Center, size.width * 0.6, colors.primary.withValues(alpha: 0.1));

    final blob2Center = Offset(
      size.width * 0.8 + math.cos(progress * 2 * math.pi) * 60,
      size.height * 0.8 + math.sin(progress * 2 * math.pi) * 60,
    );
    _drawBlob(canvas, blob2Center, size.width * 0.5, colors.secondaryContainer.withValues(alpha: 0.15));

    final blob3Center = Offset(
      size.width * 0.5 + math.sin(progress * 2 * math.pi * 0.5) * 80,
      size.height * 0.5 + math.cos(progress * 2 * math.pi * 0.5) * 80,
    );
    _drawBlob(canvas, blob3Center, size.width * 0.7, colors.tertiaryContainer.withValues(alpha: 0.08));
  }

  void _drawBlob(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _LoginBackgroundPainter oldDelegate) => 
      oldDelegate.progress != progress || oldDelegate.colors != colors;
}
