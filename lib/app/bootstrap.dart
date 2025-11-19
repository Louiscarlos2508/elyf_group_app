import 'package:flutter/widgets.dart';

/// Performs global asynchronous initialization before the app renders.
///
/// This is where we will later plug Firebase, Isar, Remote Config,
/// crash reporting, and any other shared services.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO(carlo): wire Firebase.initializeApp, Isar, and background jobs.
}
