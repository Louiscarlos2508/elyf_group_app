import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart' show currentUserIdProvider, firestoreUserServiceProvider;

/// Provider pour récupérer les données complètes du profil utilisateur depuis Firestore.
final currentUserProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>?>(
  (ref) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return null;

    try {
      final firestoreService = ref.read(firestoreUserServiceProvider);
      final userData = await firestoreService.getUserById(userId);
      return userData;
    } catch (e) {
      // Si Firestore n'est pas disponible, retourner null
      return null;
    }
  },
);

