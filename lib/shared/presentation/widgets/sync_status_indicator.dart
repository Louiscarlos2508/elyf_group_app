import 'package:flutter/material.dart';
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
  const SyncStatusIndicator({
    super.key,
    this.showLabel = false,
    this.onTap,
  });

  /// Whether to show a text label next to the icon.
  final bool showLabel;

  /// Callback when the indicator is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(
              isOnline: isOnline,
              isSyncing: isSyncing,
              hasError: hasError,
              pendingCount: pendingCount,
            ),
            if (showLabel) ...[
              const SizedBox(width: 8),
              _buildLabel(
                context: context,
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
    required bool isOnline,
    required bool isSyncing,
    required bool hasError,
    required int pendingCount,
  }) {
    if (isSyncing) {
      return const _AnimatedSyncIcon();
    }

    if (hasError) {
      return const Icon(
        Icons.cloud_off,
        color: Colors.red,
      );
    }

    if (!isOnline) {
      return const Icon(
        Icons.cloud_off,
        color: Colors.grey,
      );
    }

    if (pendingCount > 0) {
      return Badge(
        label: Text('$pendingCount'),
        child: const Icon(
          Icons.cloud_upload,
          color: Colors.blue,
        ),
      );
    }

    return const Icon(
      Icons.cloud_done,
      color: Colors.green,
    );
  }

  Widget _buildLabel({
    required BuildContext context,
    required bool isOnline,
    required bool isSyncing,
    required bool hasError,
    required int pendingCount,
  }) {
    String text;
    Color color;

    if (isSyncing) {
      text = 'Synchronisation...';
      color = Colors.blue;
    } else if (hasError) {
      text = 'Erreur de sync';
      color = Colors.red;
    } else if (!isOnline) {
      text = 'Hors ligne';
      color = Colors.grey;
    } else if (pendingCount > 0) {
      text = '$pendingCount en attente';
      color = Colors.blue;
    } else {
      text = 'Synchronisé';
      color = Colors.green;
    }

    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
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
      child: const Icon(
        Icons.sync,
        color: Colors.blue,
      ),
    );
  }
}

/// A more detailed sync status card with progress information.
class SyncStatusCard extends ConsumerWidget {
  const SyncStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final pendingCountAsync = ref.watch(pendingSyncCountProvider);
    final syncProgress = ref.watch(syncProgressProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                SyncStatusIndicator(showLabel: true),
                const Spacer(),
                if (isOnline)
                  TextButton.icon(
                    icon: const Icon(Icons.sync),
                    label: const Text('Synchroniser'),
                    onPressed: () {
                      ref.read(syncActionsProvider.notifier).triggerSync();
                    },
                  ),
              ],
            ),
            const Divider(),
            syncProgress.when(
              data: (progress) => _buildProgressInfo(context, progress),
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Text(
                'Erreur: $error',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
            const SizedBox(height: 8),
            pendingCountAsync.when(
              data: (count) => Text(
                '$count opération(s) en attente',
                style: Theme.of(context).textTheme.bodySmall,
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
    switch (progress.status) {
      case SyncStatus.idle:
        return const Text('En attente');

      case SyncStatus.syncing:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(value: progress.progress),
            const SizedBox(height: 4),
            Text(
              '${progress.current}/${progress.total} - '
              '${progress.currentOperation ?? "..."}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );

      case SyncStatus.synced:
        return Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 16),
            const SizedBox(width: 8),
            Text(
              'Synchronisation terminée (${progress.total} éléments)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );

      case SyncStatus.error:
        return Row(
          children: [
            const Icon(Icons.error, color: Colors.red, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                progress.error ?? 'Erreur inconnue',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.red),
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
          height: isOnline ? 0 : 32,
          child: isOnline
              ? const SizedBox.shrink()
              : Container(
                  color: Colors.grey[800],
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Mode hors ligne - Les données seront synchronisées',
                        style: TextStyle(color: Colors.white, fontSize: 12),
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
