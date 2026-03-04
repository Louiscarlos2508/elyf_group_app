import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/cylinder_leak.dart';
import '../../../../../../core/auth/providers.dart';
import '../../../../application/providers.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../../../../../core/errors/error_handler.dart';
import '../../../../../../core/logging/app_logger.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';

/// Item de liste pour une fuite.
class LeakListItem extends ConsumerStatefulWidget {
  const LeakListItem({super.key, required this.leak});

  final CylinderLeak leak;

  @override
  ConsumerState<LeakListItem> createState() => _LeakListItemState();
}

class _LeakListItemState extends ConsumerState<LeakListItem> {
  bool _isConverting = false;

  Color _getStatusColor(LeakStatus status) {
    switch (status) {
      case LeakStatus.reported:
        return Colors.orange;
      case LeakStatus.sentForExchange:
        return Colors.blue;
      case LeakStatus.exchanged:
        return Colors.green;
      case LeakStatus.convertedToEmpty:
        return Colors.grey;
    }
  }

  Future<void> _convertToEmpty() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Convertir en Vide'),
        content: const Text(
            'Êtes-vous sûr de vouloir convertir cette fuite en bouteille vide ? '
            'Cela sera enregistré comme une perte (le gaz s\'est échappé) et la bouteille vide sera remise en stock.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElyfButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isConverting = true);

    try {
      final authController = ref.read(authControllerProvider);
      final userId = authController.currentUser?.id ?? 'system';
      final transactionService = ref.read(transactionServiceProvider);
      
      final activeEnterprise = ref.read(activeEnterpriseProvider).value;
      final isPos = activeEnterprise?.isPointOfSale == true;
      final siteId = isPos ? activeEnterprise?.id : null;

      await transactionService.executeLeakToEmptyConversion(
        leak: widget.leak,
        siteId: siteId,
        userId: userId,
      );

      if (!mounted) return;
      NotificationService.showSuccess(context, 'Fuite convertie en bouteille vide avec succès.');
      ref.invalidate(cylinderLeaksProvider);
      ref.invalidate(cylinderStocksProvider);
    } catch (e, stackTrace) {
      if (!mounted) return;
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Erreur de conversion fuite: ${appException.message}',
        name: 'gaz.leak_conversion',
        error: e,
        stackTrace: stackTrace,
      );
      NotificationService.showError(
        context,
        ErrorHandler.instance.getUserMessage(appException),
      );
    } finally {
      if (mounted) setState(() => _isConverting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(widget.leak.status);
    final dateStr =
        '${widget.leak.reportedDate.day}/${widget.leak.reportedDate.month}/${widget.leak.reportedDate.year}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1.3,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.warning, color: statusColor, size: 24),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bouteille ${widget.leak.weight}kg',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${widget.leak.cylinderId}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: statusColor, width: 1),
                      ),
                      child: Text(
                        widget.leak.status.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Date & Action
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                dateStr,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: const Color(0xFF6A7282),
                ),
              ),
              if (widget.leak.exchangeDate != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Échangée: ${widget.leak.exchangeDate!.day}/${widget.leak.exchangeDate!.month}/${widget.leak.exchangeDate!.year}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: const Color(0xFF10B981),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (widget.leak.status == LeakStatus.reported && !_isConverting) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _convertToEmpty,
                  icon: const Icon(Icons.recycling, size: 16),
                  label: const Text('Vers Vide', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
              if (_isConverting) ...[
                 const SizedBox(height: 12),
                 const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                 ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
