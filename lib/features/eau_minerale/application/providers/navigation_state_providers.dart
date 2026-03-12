import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier pour suivre la section active du module Eau Minérale.
class CurrentSectionNotifier extends Notifier<String> {
  @override
  String build() => 'dashboard';

  void setSection(String section) => state = section;
}

/// Provider pour suivre la section active du module Eau Minérale.
/// Utilisé pour la navigation interne (ex: depuis le dashboard vers le stock).
final currentModuleSectionIdProvider = NotifierProvider<CurrentSectionNotifier, String>(CurrentSectionNotifier.new);
