import 'dart:math';

/// Configuration for retry behavior with exponential backoff.
class RetryConfig {
  const RetryConfig({
    this.maxRetries = 5,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(minutes: 5),
    this.backoffMultiplier = 2.0,
    this.jitterFactor = 0.1,
  });

  final int maxRetries;
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffMultiplier;
  final double jitterFactor; // 0.0 to 1.0, adds randomness to prevent thundering herd

  /// Default config for critical operations (e.g., payment sync)
  static const critical = RetryConfig(
    maxRetries: 10,
    initialDelay: Duration(milliseconds: 500),
    maxDelay: Duration(minutes: 10),
    backoffMultiplier: 2.0,
    jitterFactor: 0.2,
  );

  /// Default config for high priority operations
  static const high = RetryConfig(
    maxRetries: 7,
    initialDelay: Duration(seconds: 1),
    maxDelay: Duration(minutes: 5),
    backoffMultiplier: 2.0,
    jitterFactor: 0.15,
  );

  /// Default config for normal operations
  static const normal = RetryConfig(
    maxRetries: 5,
    initialDelay: Duration(seconds: 2),
    maxDelay: Duration(minutes: 3),
    backoffMultiplier: 2.0,
    jitterFactor: 0.1,
  );

  /// Default config for low priority operations
  static const low = RetryConfig(
    maxRetries: 3,
    initialDelay: Duration(seconds: 5),
    maxDelay: Duration(minutes: 2),
    backoffMultiplier: 1.5,
    jitterFactor: 0.05,
  );
}

/// Calculates retry delays using exponential backoff with jitter.
class RetryStrategy {
  RetryStrategy(this.config);

  final RetryConfig config;
  final _random = Random();

  /// Calculates the delay before the next retry attempt.
  Duration calculateDelay(int attemptNumber) {
    if (attemptNumber >= config.maxRetries) {
      return config.maxDelay;
    }

    // Calculate exponential backoff
    final exponentialDelay = config.initialDelay.inMilliseconds *
        pow(config.backoffMultiplier, attemptNumber);

    // Cap at max delay
    final cappedDelay = min(exponentialDelay, config.maxDelay.inMilliseconds.toDouble());

    // Add jitter to prevent thundering herd
    final jitter = cappedDelay * config.jitterFactor * (_random.nextDouble() - 0.5);
    final finalDelay = cappedDelay + jitter;

    return Duration(milliseconds: finalDelay.round());
  }

  /// Checks if another retry should be attempted.
  bool shouldRetry(int attemptNumber, Exception? error) {
    if (attemptNumber >= config.maxRetries) {
      return false;
    }

    // Check if error is retryable
    if (error != null && !_isRetryableError(error)) {
      return false;
    }

    return true;
  }

  /// Determines if an error is retryable.
  bool _isRetryableError(Exception error) {
    final errorString = error.toString().toLowerCase();

    // Network errors are retryable
    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('socket')) {
      return true;
    }

    // Firestore errors that are retryable
    if (errorString.contains('unavailable') ||
        errorString.contains('deadline-exceeded') ||
        errorString.contains('resource-exhausted')) {
      return true;
    }

    // Permission errors are not retryable
    if (errorString.contains('permission') ||
        errorString.contains('unauthorized') ||
        errorString.contains('forbidden')) {
      return false;
    }

    // Validation errors are not retryable
    if (errorString.contains('invalid') ||
        errorString.contains('validation')) {
      return false;
    }

    // Default: retry
    return true;
  }

  /// Executes an operation with retry logic.
  Future<T> execute<T>({
    required Future<T> Function() operation,
    String? operationName,
    void Function(int attempt, Duration delay)? onRetry,
  }) async {
    int attempt = 0;
    Exception? lastError;

    while (true) {
      try {
        return await operation();
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());

        if (!shouldRetry(attempt, lastError)) {
          rethrow;
        }

        final delay = calculateDelay(attempt);
        
        if (onRetry != null) {
          onRetry(attempt + 1, delay);
        }

        await Future.delayed(delay);
        attempt++;
      }
    }
  }
}
