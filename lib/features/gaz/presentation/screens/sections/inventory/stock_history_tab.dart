import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import 'package:elyf_groupe_app/features/audit_trail/application/providers.dart';
import 'package:elyf_groupe_app/features/audit_trail/domain/entities/audit_record.dart';

class StockHistoryTab extends ConsumerWidget {
  const StockHistoryTab({
    super.key,
    required this.enterpriseId,
  });

  final String enterpriseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(_stockAuditRecordsProvider(enterpriseId));

    return recordsAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return const EmptyState(
            icon: Icons.history,
            title: 'Aucun historique',
            message: 'Les mouvements de stock apparaîtront ici.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: records.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _HistoryCard(record: records[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorDisplayWidget(
        error: e,
        onRetry: () => ref.invalidate(_stockAuditRecordsProvider(enterpriseId)),
      ),
    );
  }
}

final _stockAuditRecordsProvider = FutureProvider.family<List<AuditRecord>, String>((ref, enterpriseId) async {
  final repo = ref.watch(auditTrailRepositoryProvider);
  final allRecords = await repo.fetchRecords(
    enterpriseId: enterpriseId,
    module: 'gaz',
  );
  
  // Filter for stock actions
  final stockActions = {
    'STOCK_REPLENISHMENT',
    'STOCK_ADJUSTMENT',
    'INTERNAL_FILLING',
    'POS_STOCK_MOVEMENT',
    'LEAK_DECLARATION',
    'LEAK_CONVERTED_TO_EMPTY',
    'INDEPENDENT_COLLECTION',
  };

  return allRecords
      .where((r) => stockActions.contains(r.action))
      .toList()
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
});

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.record});

  final AuditRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (title, icon, color) = _getActionInfo();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withAlpha(50)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      Text(
                        '${DateFormatter.formatDate(record.timestamp)} ${record.timestamp.hour.toString().padLeft(2, '0')}:${record.timestamp.minute.toString().padLeft(2, '0')}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetails(theme),
            if (record.metadata?['notes'] != null && record.metadata?['notes'].toString().isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  record.metadata?['notes'],
                  style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  (String, IconData, Color) _getActionInfo() {
    return switch (record.action) {
      'STOCK_REPLENISHMENT' => ('Réapprovisionnement', Icons.add_business_rounded, Colors.blue),
      'STOCK_ADJUSTMENT' => ('Ajustement Manuel', Icons.settings_suggest_rounded, Colors.orange),
      'INTERNAL_FILLING' => ('Remplissage Interne', Icons.opacity_rounded, Colors.purple),
      'POS_STOCK_MOVEMENT' => ('Mouvement POS', Icons.sync_alt_rounded, Colors.teal),
      'LEAK_DECLARATION' => ('Signalement Fuite', Icons.report_gmailerrorred_rounded, Colors.red),
      'LEAK_CONVERTED_TO_EMPTY' => ('Conversion Fuite -> Vide', Icons.published_with_changes_rounded, Colors.green),
      'INDEPENDENT_COLLECTION' => ('Collecte Indépendante', Icons.inventory_2, Colors.indigo),
      _ => (record.action, Icons.info_outline, Colors.grey),
    };
  }

  Widget _buildDetails(ThemeData theme) {
    // Custom builders based on action
    if (record.action == 'POS_STOCK_MOVEMENT') {
      final meta = record.metadata ?? {};
      final fullEntries = (meta['fullEntries'] as Map?)?.cast<String, dynamic>() ?? {};
      final emptyEntries = (meta['emptyEntries'] as Map?)?.cast<String, dynamic>() ?? {};
      final emptyExits = (meta['emptyExits'] as Map?)?.cast<String, dynamic>() ?? {};

      return Column(
        children: [
          if (fullEntries.isNotEmpty) _DetailRow(label: 'Pleines reçues', items: _mapToWeights(fullEntries), color: AppColors.success),
          if (emptyEntries.isNotEmpty) _DetailRow(label: 'Vides retournés', items: _mapToWeights(emptyEntries), color: Colors.blue),
          if (emptyExits.isNotEmpty) _DetailRow(label: 'Vides envoyés (Recharge)', items: _mapToWeights(emptyExits), color: AppColors.warning),
        ],
      );
    }

    if (record.action == 'STOCK_REPLENISHMENT') {
       final qty = record.metadata?['quantity'] ?? 0;
       final weight = record.metadata?['weight'] ?? 0;
       return _DetailRow(label: 'Ajouté', items: ['$qty x $weight kg'], color: Colors.blue);
    }

    if (record.action == 'STOCK_ADJUSTMENT') {
       final delta = record.metadata?['delta'] ?? 0;
       final weight = record.metadata?['weight'] ?? 0;
       final status = record.metadata?['status'] ?? '';
       final color = delta >= 0 ? AppColors.success : AppColors.danger;
       return _DetailRow(label: 'Ajusté ($status)', items: ['${delta > 0 ? "+" : ""}$delta x $weight kg'], color: color);
    }

    if (record.action == 'INTERNAL_FILLING') {
       final quantities = (record.metadata?['quantities'] as Map?)?.cast<String, dynamic>() ?? {};
       return _DetailRow(label: 'Remplis', items: _mapToWeights(quantities), color: Colors.purple);
    }

    if (record.action == 'LEAK_DECLARATION') {
       final qty = record.metadata?['quantity'] ?? 0;
       final weight = record.metadata?['weight'] ?? 0;
       return _DetailRow(label: 'Signalé', items: ['$qty x $weight kg'], color: Colors.red);
    }

    if (record.action == 'LEAK_CONVERTED_TO_EMPTY') {
       final qty = record.metadata?['quantity'] ?? 0;
       final weight = record.metadata?['weight'] ?? 0;
       return _DetailRow(label: 'Converti', items: ['$qty x $weight kg'], color: Colors.green);
    }

    if (record.action == 'INDEPENDENT_COLLECTION') {
       final fullCollect = (record.metadata?['fullCollect'] as Map?)?.cast<String, dynamic>() ?? {};
       final emptyReturn = (record.metadata?['emptyReturn'] as Map?)?.cast<String, dynamic>() ?? {};
       return Column(
         children: [
           if (fullCollect.isNotEmpty) _DetailRow(label: 'Collectées', items: _mapToWeights(fullCollect), color: Colors.indigo),
           if (emptyReturn.isNotEmpty) _DetailRow(label: 'Vides rendus', items: _mapToWeights(emptyReturn), color: Colors.blue),
         ],
       );
    }

    return Text('Détails: ${record.metadata}');
  }

  List<String> _mapToWeights(Map<String, dynamic> data) {
    return data.entries.map((e) => '${e.value} x ${e.key} kg').toList();
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.items, required this.color});
  final String label;
  final List<String> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: items.map((item) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color.withAlpha(50)),
                ),
                child: Text(item, style: theme.textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
