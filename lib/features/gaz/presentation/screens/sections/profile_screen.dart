import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/presentation/widgets/profile/profile_screen.dart'
    as shared;

/// Écran de profil du module Gaz utilisant le composant partagé.
class GazProfileScreen extends ConsumerWidget {
  const GazProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const shared.ProfileScreen();
  }
}