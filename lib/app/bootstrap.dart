import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Performs global asynchronous initialization before the app renders.
///
/// This is where we will later plug Firebase, Isar, Remote Config,
/// crash reporting, and any other shared services.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for French locale
  await initializeDateFormatting('fr', null);

  // TODO(carlo): wire Firebase.initializeApp, Isar, and background jobs.
}
