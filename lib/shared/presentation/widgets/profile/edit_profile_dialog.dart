import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/providers.dart'
    show
        currentUserIdProvider,
        currentUserProfileProvider,
        authControllerProvider;
import '../../../../core/errors/app_exceptions.dart';
import '../../../utils/utils.dart';

/// Callback optionnel pour mettre à jour le profil utilisateur.
/// Si fourni, sera utilisé au lieu de la mise à jour Firestore directe.
typedef OnProfileUpdateCallback =
    Future<void> Function({
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
  const EditProfileDialog({super.key, this.onProfileUpdate});

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
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    _loadError = null;
    Map<String, dynamic>? data;
    try {
      data = await ref.read(currentUserProfileProvider.future);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.toString());
      return;
    }
    if (!mounted) return;
    if (data == null) {
      setState(() => _loadError = 'Profil introuvable');
      return;
    }
    setState(() {
      _currentUserData = data;
      _firstNameController.text = data!['firstName'] as String? ?? '';
      _lastNameController.text = data['lastName'] as String? ?? '';
      _usernameController.text = data['username'] as String? ?? '';
      _emailController.text = data['email'] as String? ?? '';
      _phoneController.text = data['phone'] as String? ?? '';
    });
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
    if (!_formKey.currentState!.validate()) return;
    if (_currentUserData == null) {
      if (mounted) {
        NotificationService.showError(context, 'Profil non chargé');
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUserId = ref.read(currentUserIdProvider);
      if (currentUserId == null) {
        throw AuthenticationException(
          'Utilisateur non connecté',
          'USER_NOT_AUTHENTICATED',
        );
      }

      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final username = _usernameController.text.trim();
      final email = _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim();
      final rawPhone = _phoneController.text.trim();
      final phone = rawPhone.isEmpty
          ? null
          : (PhoneUtils.normalizeBurkina(rawPhone) ?? rawPhone);

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
        NotificationService.showSuccess(
          context,
          'Profil mis à jour avec succès',
        );
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
    final colors = theme.colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final availableHeight =
        screenHeight - 100;
    final maxWidth = 500.0;
    final hasData = _currentUserData != null;
    final hasError = _loadError != null;

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
                child: hasData
                    ? SingleChildScrollView(
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
                                hintText: '+226 70 00 00 00',
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? null
                                      : Validators.phoneBurkina(v),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      )
                    : Center(
                        child: hasError
                            ? Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 40,
                                      color: colors.error,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _loadError!,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                        color: colors.onSurfaceVariant,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                    color: colors.primary,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Chargement du profil…',
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
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
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
                    if (hasData) ...[
                      const SizedBox(width: 16),
                      IntrinsicWidth(
                        child: FilledButton(
                          onPressed: _isLoading ? null : _handleSubmit,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Enregistrer'),
                        ),
                      ),
                    ] else if (hasError) ...[
                      const SizedBox(width: 16),
                      FilledButton.icon(
                        onPressed: () {
                          _loadError = null;
                          _loadProfile();
                        },
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Réessayer'),
                      ),
                    ],
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
