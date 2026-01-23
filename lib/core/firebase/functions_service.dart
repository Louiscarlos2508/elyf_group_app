import 'dart:developer' as developer;

import 'package:cloud_functions/cloud_functions.dart';

import '../errors/app_exceptions.dart';
import '../errors/error_handler.dart';
import '../logging/app_logger.dart';

/// Service pour appeler les Cloud Functions Firebase de manière sécurisée.
///
/// Ce service gère :
/// - Les appels Cloud Functions avec gestion d'erreurs
/// - Le retry automatique en cas d'échec
/// - Le support multi-tenant (enterpriseId, moduleId)
/// - La validation des réponses
class FunctionsService {
  FunctionsService({
    required this.functions,
    this.defaultTimeout = const Duration(seconds: 30),
    this.maxRetries = 3,
  });

  final FirebaseFunctions functions;
  final Duration defaultTimeout;
  final int maxRetries;

  /// Appelle une Cloud Function avec gestion d'erreurs et retry.
  ///
  /// [functionName] : Nom de la fonction à appeler
  /// [data] : Données à envoyer à la fonction
  /// [enterpriseId] : ID de l'entreprise (ajouté automatiquement)
  /// [moduleId] : ID du module (ajouté automatiquement si fourni)
  /// [timeout] : Timeout personnalisé (optionnel)
  Future<Map<String, dynamic>> callFunction({
    required String functionName,
    required Map<String, dynamic> data,
    required String enterpriseId,
    String? moduleId,
    Duration? timeout,
  }) async {
    final effectiveTimeout = timeout ?? defaultTimeout;
    int attempts = 0;

    // Ajouter les métadonnées multi-tenant
    final dataWithMetadata = Map<String, dynamic>.from(data)
      ..['enterpriseId'] = enterpriseId;

    if (moduleId != null && moduleId.isNotEmpty) {
      dataWithMetadata['moduleId'] = moduleId;
    }

    while (attempts < maxRetries) {
      try {
        developer.log(
          'Calling Cloud Function: $functionName (attempt ${attempts + 1}/$maxRetries)',
          name: 'functions.service',
        );

        final callable = functions.httpsCallable(
          functionName,
          options: HttpsCallableOptions(timeout: effectiveTimeout),
        );

        final result = await callable.call(dataWithMetadata);
        final responseData = result.data as Map<String, dynamic>?;

        developer.log(
          'Cloud Function $functionName succeeded',
          name: 'functions.service',
        );

        return responseData ?? {};
      } catch (e, stackTrace) {
        attempts++;
        final appException = ErrorHandler.instance.handleError(e, stackTrace);

        // Si c'est la dernière tentative, rethrow
        if (attempts >= maxRetries) {
          AppLogger.error(
            'Cloud Function $functionName failed after $maxRetries attempts: ${appException.message}',
            name: 'functions.service',
            error: e,
            stackTrace: stackTrace,
          );
          rethrow;
        }

        // Attendre avant de réessayer (backoff exponentiel)
        final delay = Duration(milliseconds: 1000 * (1 << (attempts - 1)));
        AppLogger.warning(
          'Cloud Function $functionName failed, retrying in ${delay.inMilliseconds}ms: ${appException.message}',
          name: 'functions.service',
          error: e,
          stackTrace: stackTrace,
        );

        await Future<void>.delayed(delay);
      }
    }

    throw NetworkException(
      'Failed to call Cloud Function after $maxRetries attempts',
      'CLOUD_FUNCTION_CALL_FAILED',
    );
  }

  /// Appelle une Cloud Function et retourne le résultat typé.
  ///
  /// Utilise [fromJson] pour convertir la réponse en objet typé.
  Future<T> callFunctionTyped<T>({
    required String functionName,
    required Map<String, dynamic> data,
    required String enterpriseId,
    String? moduleId,
    required T Function(Map<String, dynamic>) fromJson,
    Duration? timeout,
  }) async {
    final response = await callFunction(
      functionName: functionName,
      data: data,
      enterpriseId: enterpriseId,
      moduleId: moduleId,
      timeout: timeout,
    );

    return fromJson(response);
  }

  /// Appelle une Cloud Function qui ne retourne rien (void).
  Future<void> callFunctionVoid({
    required String functionName,
    required Map<String, dynamic> data,
    required String enterpriseId,
    String? moduleId,
    Duration? timeout,
  }) async {
    await callFunction(
      functionName: functionName,
      data: data,
      enterpriseId: enterpriseId,
      moduleId: moduleId,
      timeout: timeout,
    );
  }
}
