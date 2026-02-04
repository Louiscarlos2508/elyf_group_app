import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/offline/providers.dart';
import '../../../core/offline/sync_manager.dart';
import '../../../core/offline/sync_status.dart';

/// A widget that displays the current sync status.
///
/// Shows different states:
/// - Online and synced (green cloud icon)
/// - Online with pending sync (blue cloud icon with badge)
/// - Syncing in progress (animated sync icon)
/// - Offline (grey cloud off icon)
/// - Error (red warning icon)
class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key, this.showLabel = false, this.onTap});

  /// Whether to show a text label next to the icon.
  final bool showLabel;

  /// Callback when the indicator is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isOnline = ref.watch(isOnlineProvider);
    final pendingCountAsync = ref.watch(pendingSyncCountProvider);
    final syncProgress = ref.watch(syncProgressProvider);

    final isSyncing = syncProgress.maybeWhen(
      data: (p) => p.status == SyncStatus.syncing,
      orElse: () => false,
    );

    final hasError = syncProgress.maybeWhen(
      data: (p) => p.status == SyncStatus.error,
      orElse: () => false,
    );

    final pendingCount = pendingCountAsync.maybeWhen(
      data: (count) => count,
      orElse: () => 0,
    );

    final statusColors = theme.extension<StatusColors>();
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(
              theme: theme,
              statusColors: statusColors,
              isOnline: isOnline,
              isSyncing: isSyncing,
              hasError: hasError,
              pendingCount: pendingCount,
            ),
            if (showLabel) ...[
              const SizedBox(width: 8),
              _buildLabel(
                context: context,
                statusColors: statusColors,
                isOnline: isOnline,
                isSyncing: isSyncing,
                hasError: hasError,
                pendingCount: pendingCount,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon({
    required ThemeData theme,
    StatusColors? statusColors,
    required bool isOnline,
    required bool isSyncing,
    required bool hasError,
    required int pendingCount,
  }) {
    if (isSyncing) {
      return const _AnimatedSyncIcon();
    }

    if (hasError) {
      return Icon(Icons.cloud_off, color: theme.colorScheme.error, size: 18);
    }

    if (!isOnline) {
      return Icon(Icons.cloud_off, color: theme.colorScheme.onSurfaceVariant, size: 18);
    }

    if (pendingCount > 0) {
      return Badge(
        label: Text('$pendingCount'),
        backgroundColor: theme.colorScheme.primary,
        child: Icon(Icons.cloud_upload, color: theme.colorScheme.primary, size: 18),
      );
    }

    return Icon(
      Icons.cloud_done, 
      color: statusColors?.success ?? Colors.green, 
      size: 18,
    );
  }

  Widget _buildLabel({
    required BuildContext context,
    StatusColors? statusColors,
    required bool isOnline,
    required bool isSyncing,
    required bool hasError,
    required int pendingCount,
  }) {
    final theme = Theme.of(context);
    String text;
    Color color;

    if (isSyncing) {
      text = 'Synchronisation...';
      color = theme.colorScheme.primary;
    } else if (hasError) {
      text = 'Erreur de sync';
      color = theme.colorScheme.error;
    } else if (!isOnline) {
      text = 'Hors ligne';
      color = theme.colorScheme.onSurfaceVariant;
    } else if (pendingCount > 0) {
      text = '$pendingCount en attente';
      color = theme.colorScheme.primary;
    } else {
      text = 'Synchronisé';
      color = statusColors?.success ?? Colors.green;
    }

    return Text(
      text,
      style: theme.textTheme.labelSmall?.copyWith(
        color: color,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

/// Animated sync icon that rotates while syncing.
class _AnimatedSyncIcon extends StatefulWidget {
  const _AnimatedSyncIcon();

  @override
  State<_AnimatedSyncIcon> createState() => _AnimatedSyncIconState();
}

class _AnimatedSyncIconState extends State<_AnimatedSyncIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(Icons.sync, color: Theme.of(context).colorScheme.primary, size: 18),
    );
  }
}

/// A more detailed sync status card with progress information.
class SyncStatusCard extends ConsumerWidget {
  const SyncStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isOnline = ref.watch(isOnlineProvider);
    final pendingCountAsync = ref.watch(pendingSyncCountProvider);
    final syncProgress = ref.watch(syncProgressProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const SyncStatusIndicator(showLabel: true),
                const Spacer(),
                if (isOnline)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: const Size(0, 36),
                    ),
                    icon: const Icon(Icons.sync, size: 16),
                    label: const Text('Synchroniser', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      ref.read(syncActionsProvider.notifier).triggerSync();
                    },
                  ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(),
            ),
            syncProgress.when(
              data: (progress) => _buildProgressInfo(context, progress),
              loading: () => LinearProgressIndicator(
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              error: (error, _) => Row(
                children: [
                  Icon(Icons.error_outline, color: theme.colorScheme.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Erreur: $error',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            pendingCountAsync.when(
              data: (count) => Row(
                children: [
                  Icon(
                    Icons.pending_actions,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$count opération(s) en attente',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressInfo(BuildContext context, SyncProgress progress) {
    final theme = Theme.of(context);
    final statusColors = theme.extension<StatusColors>();

    switch (progress.status) {
      case SyncStatus.idle:
        return Text(
          'En attente',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        );

      case SyncStatus.syncing:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.progress,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    progress.currentOperation ?? "Traitement...",
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${progress.current}/${progress.total}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        );

      case SyncStatus.synced:
        return Row(
          children: [
            Icon(
              Icons.check_circle, 
              color: statusColors?.success ?? Colors.green, 
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Synchronisation terminée (${progress.total} éléments)',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: statusColors?.success ?? Colors.green,
              ),
            ),
          ],
        );

      case SyncStatus.error:
        return Row(
          children: [
            Icon(Icons.error, color: theme.colorScheme.error, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                progress.error ?? 'Erreur inconnue',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        );
    }
  }
}

/// Banner that appears at the top of the screen when offline.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: isOnline ? 0 : 36,
          child: isOnline
              ? const SizedBox.shrink()
              : Container(
                  color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.9),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_off, 
                        color: Theme.of(context).colorScheme.onErrorContainer, 
                        size: 14,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Mode hors ligne actif',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
