import 'package:flutter/material.dart';
import 'app_exceptions.dart';
import 'error_handler.dart';

/// Widget pour afficher une erreur de manière uniforme.
class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.compact = false,
  });

  final AppException error;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = ErrorHandler.instance.getErrorTitle(error);
    final message = ErrorHandler.instance.getUserMessage(error);

    if (compact) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(_getIcon(), color: _getColor(theme), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: _getColor(theme),
                ),
              ),
            ),
            if (onRetry != null)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: onRetry,
                tooltip: 'Réessayer',
              ),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getIcon(), size: 64, color: _getColor(theme)),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: _getColor(theme),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    return switch (error) {
      NetworkException() => Icons.wifi_off,
      AuthenticationException() => Icons.lock_outline,
      AuthorizationException() => Icons.block,
      ValidationException() => Icons.error_outline,
      NotFoundException() => Icons.search_off,
      StorageException() => Icons.storage,
      SyncException() => Icons.sync_problem,
      UnknownException() => Icons.error_outline,
      _ => Icons.error_outline,
    };
  }

  Color _getColor(ThemeData theme) {
    return switch (error) {
      NetworkException() => Colors.orange,
      AuthenticationException() => Colors.red,
      AuthorizationException() => Colors.red,
      ValidationException() => Colors.orange,
      NotFoundException() => Colors.grey,
      StorageException() => Colors.orange,
      SyncException() => Colors.blue,
      UnknownException() => theme.colorScheme.error,
      _ => theme.colorScheme.error,
    };
  }
}

/// Widget pour afficher une erreur avec un Future.
class AsyncErrorWidget extends StatelessWidget {
  const AsyncErrorWidget({
    super.key,
    required this.error,
    this.stackTrace,
    this.onRetry,
    this.compact = false,
  });

  final Object error;
  final StackTrace? stackTrace;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final appException = ErrorHandler.instance.handleError(error, stackTrace);
    return AppErrorWidget(
      error: appException,
      onRetry: onRetry,
      compact: compact,
    );
  }
}
