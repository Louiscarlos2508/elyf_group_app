
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/gaz_session.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:intl/intl.dart';

class GazSessionsReportContent extends ConsumerWidget {
  const GazSessionsReportContent({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  final DateTime startDate;
  final DateTime endDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(gazSessionsProvider);

    return sessionsAsync.when(
      data: (sessions) {
        final filteredSessions = sessions.where((s) {
          final date = s.date;
          if (date == null) return false;
          return date.isAfter(startDate.subtract(const Duration(days: 1))) &&
              date.isBefore(endDate.add(const Duration(days: 1)));
        }).toList()
          ..sort((a, b) => (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)));

        if (filteredSessions.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Aucune clôture de session pour cette période.'),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredSessions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final session = filteredSessions[index];
            return _SessionClosureCard(session: session);
          },
        );
      },
      loading: () => AppShimmers.list(context),
      error: (error, _) => Center(child: Text('Erreur: $error')),
    );
  }
}

class _SessionClosureCard extends StatelessWidget {
  const _SessionClosureCard({required this.session});
  final GazSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diff = session.physicalCash - session.theoreticalCash;
    final isPositive = diff >= 0;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ExpansionTile(
        title: Text(
          DateFormat('dd MMMM yyyy').format(session.date ?? DateTime.now()),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Reçu: ${CurrencyFormatter.formatDouble(session.physicalCash)}',
          style: TextStyle(color: theme.colorScheme.primary),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: (isPositive ? Colors.green : Colors.red).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${isPositive ? '+' : ''}${CurrencyFormatter.formatDouble(diff)}',
            style: TextStyle(
              color: isPositive ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Ventes Totales', CurrencyFormatter.formatDouble(session.totalSales)),
                _buildInfoRow('Dépenses', CurrencyFormatter.formatDouble(session.totalExpenses)),
                _buildInfoRow('Cash Théorique', CurrencyFormatter.formatDouble(session.theoreticalCash)),
                const Divider(),
                _buildInfoRow('Clôturé par', session.closedBy ?? 'Inconnu'),
                if (session.stockReconciliation.isNotEmpty) ...[
                  const Divider(),
                  const Text('Écarts de Stock:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 4),
                  ...session.stockReconciliation.entries.map((e) {
                    final isPositive = e.value > 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${e.key}kg (${session.theoreticalStock[e.key] ?? 0} théo.)', style: const TextStyle(fontSize: 12)),
                          Text(
                            '${isPositive ? '+' : ''}${e.value}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: e.value == 0 ? Colors.grey : (isPositive ? Colors.green : Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                if (session.notes != null && session.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text(session.notes!, style: const TextStyle(fontSize: 12)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
