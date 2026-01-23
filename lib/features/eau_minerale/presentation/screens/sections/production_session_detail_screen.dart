import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_theme.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../../domain/entities/production_session.dart';
import '../../../domain/entities/sale.dart';
import '../../../domain/services/production_margin_calculator.dart';
import '../../../domain/entities/machine.dart';
import '../../widgets/production_detail_report.dart';
import '../../widgets/section_placeholder.dart';
// Removed: ventesParSessionProvider is imported from providers.dart
import '../../../domain/entities/bobine_usage.dart';
import 'production_session_form_screen.dart';
import '../../widgets/production_tracking/personnel_section.dart';

/// Écran de détail d'une session de production.
class ProductionSessionDetailScreen extends ConsumerStatefulWidget {
  const ProductionSessionDetailScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<ProductionSessionDetailScreen> createState() =>
      _ProductionSessionDetailScreenState();
}

class _ProductionSessionDetailScreenState
    extends ConsumerState<ProductionSessionDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(
      productionSessionDetailProvider((widget.sessionId)),
    );
    final ventesAsync = ref.watch(ventesParSessionProvider((widget.sessionId)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail session'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Détails', icon: Icon(Icons.info_outline)),
            Tab(text: 'Rapport', icon: Icon(Icons.assessment)),
          ],
        ),
        actions: [
          sessionAsync.when(
            data: (session) => IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditForm(context, ref, session),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Onglet Détails
          sessionAsync.when(
            data: (session) => _ProductionSessionDetailContent(
              sessionId: widget.sessionId,
              ventesAsync: ventesAsync,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => SectionPlaceholder(
              icon: Icons.error_outline,
              title: 'Erreur de chargement',
              subtitle: 'Impossible de charger les détails de la session.',
              primaryActionLabel: 'Réessayer',
              onPrimaryAction: () => ref.invalidate(
                productionSessionDetailProvider((widget.sessionId)),
              ),
            ),
          ),
          // Onglet Rapport
          _ProductionSessionReportContent(sessionId: widget.sessionId),
        ],
      ),
    );
  }

  void _showEditForm(
    BuildContext context,
    WidgetRef ref,
    ProductionSession session,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductionSessionFormScreen(session: session),
      ),
    );
  }
}

class _ProductionSessionDetailContent extends ConsumerWidget {
  const _ProductionSessionDetailContent({
    required this.sessionId,
    required this.ventesAsync,
  });

  final String sessionId;
  final AsyncValue<List<Sale>> ventesAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(
      productionSessionDetailProvider((sessionId)),
    );

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(productionSessionDetailProvider((sessionId)));
        ref.invalidate(ventesParSessionProvider((sessionId)));
        await Future.wait([
          ref.read(productionSessionDetailProvider((sessionId)).future),
          ref.read(ventesParSessionProvider((sessionId)).future),
        ]);
      },
      child: sessionAsync.when(
        data: (session) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(context, session),
              const SizedBox(height: 16),
              _buildConsumptionCard(context, session),
              const SizedBox(height: 16),
              _buildMachinesCard(context, session),
              const SizedBox(height: 16),
              _buildBobinesCard(context, session),
              const SizedBox(height: 16),
              PersonnelSection(session: session),
              const SizedBox(height: 16),
              ventesAsync.when(
                data: (ventes) => _buildMarginCard(context, session, ventes),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => _buildMarginCard(context, session, []),
              ),
              if (session.notes != null) ...[
                const SizedBox(height: 16),
                _buildNotesCard(context, session),
              ],
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SectionPlaceholder(
            icon: Icons.error_outline,
            title: 'Erreur de chargement',
            subtitle: 'Impossible de charger les détails de la session.',
            primaryActionLabel: 'Réessayer',
            onPrimaryAction: () =>
                ref.invalidate(productionSessionDetailProvider((sessionId))),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, ProductionSession session) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations générales',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildInfoRow(context, 'Date', _formatDate(session.date)),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              'Heure début',
              _formatTime(session.heureDebut),
            ),
            const SizedBox(height: 12),
            if (session.heureFin != null)
              _buildInfoRow(
                context,
                'Heure fin',
                _formatTime(session.heureFin!),
              ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              'Durée',
              '${session.dureeHeures.toStringAsFixed(1)} heures',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              'Quantité produite',
              '${session.quantiteProduite} ${session.quantiteProduiteUnite}',
            ),
            if (session.emballagesUtilises != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                'Emballages utilisés',
                '${session.emballagesUtilises} packs',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConsumptionCard(
    BuildContext context,
    ProductionSession session,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_buildConsumptionInfoRow(context, session)],
        ),
      ),
    );
  }

  Widget _buildMachinesCard(BuildContext context, ProductionSession session) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Machines utilisées',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Consumer(
              builder: (context, ref, child) {
                final machinesAsync = ref.watch(allMachinesProvider);
                return machinesAsync.when(
                  data: (machines) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: session.machinesUtilisees.map((machineId) {
                        final machine = machines.where((m) => m.id == machineId).firstOrNull;
                        final name = machine?.nom ?? machineId;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.precision_manufacturing, size: 16),
                              const SizedBox(width: 8),
                              Text(name),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  error: (_, __) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: session.machinesUtilisees.map((machineId) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.precision_manufacturing, size: 16),
                            const SizedBox(width: 8),
                            Text(machineId),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBobinesCard(BuildContext context, ProductionSession session) {
    final theme = Theme.of(context);
    
    // Grouper les bobines par machine
    final bobinesParMachine = <String, List<BobineUsage>>{};
    for (final bobine in session.bobinesUtilisees) {
      if (!bobinesParMachine.containsKey(bobine.machineName)) {
        bobinesParMachine[bobine.machineName] = [];
      }
      bobinesParMachine[bobine.machineName]!.add(bobine);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.album, 
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Utilisation des Bobines',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (session.bobinesUtilisees.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Aucune bobine installée pour le moment.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              ...bobinesParMachine.entries.map((entry) {
                final machineName = entry.key;
                final bobines = entry.value;
                // Trier par date d'installation (plus récent en haut ou en bas ? En bas c'est plus logique pour une timeline)
                bobines.sort((a, b) => a.heureInstallation.compareTo(b.heureInstallation));

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.precision_manufacturing,
                            size: 16,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            machineName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                            width: 2,
                          ),
                        ),
                      ),
                      margin: const EdgeInsets.only(left: 7), // Aligner avec l'icône machine
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        children: bobines.map((bobine) {
                          final isLast = bobine == bobines.last;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildBobineTile(context, bobine, isLast),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildBobineTile(BuildContext context, BobineUsage bobine, bool isLast) {
    final theme = Theme.of(context);
    final isFinished = bobine.estFinie;
    final isActive = !isFinished;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive 
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: isActive 
            ? Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.5))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isActive ? Icons.rotate_right : Icons.check_circle_outline,
                size: 20,
                color: isActive ? theme.colorScheme.primary : theme.colorScheme.outline,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  bobine.bobineType,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                    decoration: isFinished ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'EN COURS',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 28), // Aligner sous le texte
            child: Text(
              'Installée à ${_formatTime(bobine.heureInstallation)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (isFinished)
            Padding(
              padding: const EdgeInsets.only(left: 28, top: 2),
              child: Text(
                'Terminée et remplacée',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMarginCard(
    BuildContext context,
    ProductionSession session,
    List<Sale> ventes,
  ) {
    final theme = Theme.of(context);
    final marge = ProductionMarginCalculator.calculerMarge(
      session: session,
      ventesLiees: ventes,
    );

    final statusColors = Theme.of(context).extension<StatusColors>()!;
    final marginColor = marge.estRentable
        ? statusColors.success
        : statusColors.danger;
    return Card(
      color: marginColor.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: marginColor.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: marginColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    marge.estRentable ? Icons.trending_up : Icons.trending_down,
                    color: marginColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Analyse de marge',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(
              context,
              'Revenus totaux',
              '${marge.revenusTotaux} CFA',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(context, 'Coût bobines', '${marge.coutBobines} CFA'),
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              'Coût électricité',
              '${marge.coutElectricite} CFA',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(context, 'Coût total', '${marge.coutTotal} CFA'),
            const SizedBox(height: 16),
            Divider(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              thickness: 1,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              'Marge brute',
              '${marge.margeBrute} CFA',
              isBold: true,
              valueColor: marginColor,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              'Pourcentage marge',
              marge.pourcentageMargeFormate,
              isBold: true,
              valueColor: marginColor,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              'Nombre ventes',
              marge.nombreVentes.toString(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(BuildContext context, ProductionSession session) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(session.notes!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildConsumptionInfoRow(
    BuildContext context,
    ProductionSession session,
  ) {
    return Consumer(
      builder: (context, ref, child) {
        final meterTypeAsync = ref.watch(electricityMeterTypeProvider);

        return meterTypeAsync.when(
          data: (meterType) {
            return _buildInfoRow(
              context,
              'Consommation courant',
              '${session.consommationCourant.toStringAsFixed(2)} ${meterType.unit}',
            );
          },
          loading: () => _buildInfoRow(
            context,
            'Consommation courant',
            session.consommationCourant.toStringAsFixed(2),
          ),
          error: (_, __) => _buildInfoRow(
            context,
            'Consommation courant',
            session.consommationCourant.toStringAsFixed(2),
          ),
        );
      },
    );
  }
}

class _ProductionSessionReportContent extends ConsumerWidget {
  const _ProductionSessionReportContent({required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(
      productionSessionDetailProvider((sessionId)),
    );

    return sessionAsync.when(
      data: (session) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ProductionDetailReport(session: session),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => SectionPlaceholder(
        icon: Icons.error_outline,
        title: 'Erreur de chargement',
        subtitle: 'Impossible de charger les détails de la session.',
        primaryActionLabel: 'Réessayer',
        onPrimaryAction: () =>
            ref.invalidate(productionSessionDetailProvider((sessionId))),
      ),
    );
  }
}
