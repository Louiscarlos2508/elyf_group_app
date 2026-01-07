import 'dart:math' as math;
import 'dart:developer' as developer;

import 'sync_manager.dart';
import 'sync_status.dart';

/// Handles retry logic with exponential backoff.
///
/// Extracted from SyncManager to improve maintainability.
class RetryHandler {
  RetryHandler({
    required this.config,
  });

  final SyncConfig config;

  /// Calculates exponential backoff delay with jitter.
  ///
  /// Formula: base * 2^retryCount, capped at maxDelay, with ±25% jitter.
  int calculateBackoffDelay(int retryCount) {
    // Exponential backoff: base * 2^retryCount
    final exponentialDelay =
        config.baseRetryDelayMs * math.pow(2, retryCount).toInt();

    // Cap at max delay
    final cappedDelay = math.min(exponentialDelay, config.maxRetryDelayMs);

    // Add jitter (±25%)
    final jitter = (cappedDelay * 0.25 * (math.Random().nextDouble() - 0.5))
        .toInt();

    return cappedDelay + jitter;
  }

  /// Checks if max retries have been exceeded.
  bool hasExceededMaxRetries(int retryCount) {
    return retryCount >= config.maxRetryAttempts;
  }

  /// Waits for retry delay if needed.
  ///
  /// Logs the retry attempt and waits for the calculated delay.
  Future<void> waitForRetry(int retryCount) async {
    if (retryCount > 0) {
      final delayMs = calculateBackoffDelay(retryCount);
      developer.log(
        'Retry $retryCount/${config.maxRetryAttempts}, waiting ${delayMs}ms',
        name: 'offline.retry',
      );
      await Future<void>.delayed(Duration(milliseconds: delayMs));
    }
  }
}

