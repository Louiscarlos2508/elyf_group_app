import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../core/offline/connectivity_service.dart';
import '../core/offline/isar_service.dart';

/// Performs global asynchronous initialization before the app renders.
///
/// This is where we initialize Firebase, Isar, Remote Config,
/// crash reporting, and any other shared services.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // .env file might not exist in development, that's okay
    // The app will use default values or throw errors if required vars are missing
  }

  // Initialize date formatting for French locale
  await initializeDateFormatting('fr', null);

  // Initialize offline-first infrastructure
  await _initializeOfflineServices();

  // TODO(carlo): wire Firebase.initializeApp and background jobs.
}

/// Initializes offline-first services (Isar database and connectivity).
Future<void> _initializeOfflineServices() async {
  try {
    // Initialize Isar database
    await IsarService.instance.initialize();

    // Initialize connectivity monitoring
    final connectivityService = ConnectivityService();
    await connectivityService.initialize();

    developer.log(
      'Offline services initialized successfully',
      name: 'bootstrap',
    );
  } catch (error, stackTrace) {
    developer.log(
      'Failed to initialize offline services',
      name: 'bootstrap',
      error: error,
      stackTrace: stackTrace,
    );
    // Continue app startup even if offline services fail
    // The app should still work in online-only mode
  }
}
