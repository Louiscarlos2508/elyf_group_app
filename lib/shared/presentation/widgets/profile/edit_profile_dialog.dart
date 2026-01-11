import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/providers.dart' show currentUserIdProvider, currentUserProfileProvider, authControllerProvider;
import '../../../utils/notification_service.dart';

/// Callback optionnel pour mettre à jour le profil utilisateur.
/// Si fourni, sera utilisé au lieu de la mise à jour Firestore directe.
typedef OnProfileUpdateCallback = Future<void> Function({
  required String userId,
  required String firstName,
  required String lastName,
  required String username,
  String? email,
  String? phone,
});

/// Dialog pour modifier le profil de l'utilisateur actuel.
/// 
/// Utilise Firestore directement ou un callback optionnel pour la mise à jour.
class EditProfileDialog extends ConsumerStatefulWidget {
  const EditProfileDialog({
    super.key,
    this.onProfileUpdate,
  });

  /// Callback optionnel pour la mise à jour du profil.
  /// Si fourni, sera utilisé au lieu de la mise à jour Firestore directe.
  final OnProfileUpdateCallback? onProfileUpdate;

  @override
  ConsumerState<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  bool _isLoading = false;
  Map<String, dynamic>? _currentUserData;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Vérifier que les données utilisateur sont bien chargées
    if (_currentUserData == null) {
      // Essayer de charger les données une dernière fois
      final profileAsync = await ref.read(currentUserProfileProvider.future);
      if (profileAsync == null) {
        if (mounted) {
          NotificationService.showError(context, 'Utilisateur non trouvé');
        }
        return;
      }
      setState(() {
        _currentUserData = profileAsync;
      });
    }

    setState(() => _isLoading = true);

    try {
      final currentUserId = ref.read(currentUserIdProvider);
      if (currentUserId == null) {
        throw Exception('Utilisateur non connecté');
      }

      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final username = _usernameController.text.trim();
      final email = _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim();
      final phone = _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim();

      // Utiliser le callback si fourni (pour des cas spécifiques comme administration),
      // sinon utiliser le controller d'authentification partagé
      if (widget.onProfileUpdate != null) {
        await widget.onProfileUpdate!(
          userId: currentUserId,
          firstName: firstName,
          lastName: lastName,
          username: username,
          email: email,
          phone: phone,
        );
      } else {
        // Mise à jour via le controller d'authentification partagé
        final authController = ref.read(authControllerProvider);
        await authController.updateProfile(
          userId: currentUserId,
          email: email ?? _currentUserData!['email'] as String? ?? '',
          firstName: firstName,
          lastName: lastName,
          username: username,
          phone: phone,
          isActive: _currentUserData!['isActive'] as bool? ?? true,
          isAdmin: _currentUserData!['isAdmin'] as bool? ?? false,
        );
      }

      if (mounted) {
        ref.invalidate(currentUserProfileProvider);
        Navigator.of(context).pop(true);
        NotificationService.showSuccess(context, 'Profil mis à jour avec succès');
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final availableHeight = screenHeight - 100; // Espace pour le padding et les marges
    final maxWidth = 500.0;

    // Charger les données utilisateur de manière réactive
    final profileAsync = ref.watch(currentUserProfileProvider);

    // Charger les données si pas encore chargées
    if (_currentUserData == null && profileAsync.value != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _currentUserData = profileAsync.value;
            _firstNameController.text = profileAsync.value!['firstName'] as String? ?? '';
            _lastNameController.text = profileAsync.value!['lastName'] as String? ?? '';
            _usernameController.text = profileAsync.value!['username'] as String? ?? '';
            _emailController.text = profileAsync.value!['email'] as String? ?? '';
            _phoneController.text = profileAsync.value!['phone'] as String? ?? '';
          });
        }
      });
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: availableHeight.clamp(300.0, screenHeight * 0.9),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Modifier mon profil',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'Prénom *',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le prénom est requis';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom *',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le nom est requis';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom d\'utilisateur *',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le nom d\'utilisateur est requis';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Téléphone',
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 16),
                    IntrinsicWidth(
                      child: FilledButton(
                        onPressed: _isLoading || _currentUserData == null
                            ? null
                            : _handleSubmit,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Enregistrer'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

