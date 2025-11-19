import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global boot status to toggle themes or loaders before the app is ready.
enum AppBootStatus { initializing, ready }

final appBootStatusProvider = Provider<AppBootStatus>(
  (ref) => AppBootStatus.ready,
);
