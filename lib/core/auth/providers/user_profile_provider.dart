import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/administration/application/providers.dart' show userRepositoryProvider;
import '../providers.dart' show currentUserIdProvider;

/// Provider pour récupérer les données complètes du profil utilisateur.
/// Supporte le mode hors-ligne en utilisant UserRepository (Drift + Sync).
/// Non autoDispose pour éviter un rechargement à chaque visite du profil.
final currentUserProfileProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  try {
    final userRepository = ref.read(userRepositoryProvider);
    final user = await userRepository.getUserById(userId);
    
    if (user != null) {
      return {
        'id': user.id,
        'firstName': user.firstName,
        'lastName': user.lastName,
        'username': user.username,
        'email': user.email,
        'phone': user.phone,
        'isActive': user.isActive,
        'createdAt': user.createdAt?.toIso8601String(),
        'updatedAt': user.updatedAt?.toIso8601String(),
      };
    }
    return null;
  } catch (e) {
    // Si une erreur survient (ex: base locale non initialisée), retourner null
    return null;
  }
});
