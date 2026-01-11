import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_theme.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../../domain/entities/production_session.dart';
import '../../../domain/entities/sale.dart';
import '../../../domain/services/production_margin_calculator.dart';
import '../../widgets/production_detail_report.dart';
import '../../widgets/section_placeholder.dart';
// Removed: ventesParSessionProvider is imported from providers.dart
import 'production_session_form_screen.dart';

/// Écran de détail d'une session de production.
class ProductionSessionDetailScreen extends ConsumerStatefulWidget {
  const ProductionSessionDetailScreen({
    super.key,
    required this.sessionId,
  });

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
              onPrimaryAction: () => ref.invalidate(productionSessionDetailProvider((widget.sessionId))),
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
    final sessionAsync = ref.watch(productionSessionDetailProvider((sessionId)));
    
    return sessionAsync.when(
      data: (session) => SingleChildScrollView(
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
            ventesAsync.when(
              data: (ventes) => _buildMarginCard(context, session, ventes),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            if (session.notes != null) ...[
              const SizedBox(height: 16),
              _buildNotesCard(context, session),
            ],
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => SectionPlaceholder(
        icon: Icons.error_outline,
        title: 'Erreur de chargement',
        subtitle: 'Impossible de charger les détails de la session.',
        primaryActionLabel: 'Réessayer',
        onPrimaryAction: () => ref.invalidate(productionSessionDetailProvider((sessionId))),
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
            _buildInfoRow(context, 'Heure début', _formatTime(session.heureDebut)),
            const SizedBox(height: 12),
            if (session.heureFin != null)
              _buildInfoRow(context, 'Heure fin', _formatTime(session.heureFin!)),
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
          children: [
            _buildConsumptionInfoRow(context, session),
          ],
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
            ...session.machinesUtilisees.map(
              (machineId) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.precision_manufacturing, size: 16),
                    const SizedBox(width: 8),
                    Text(machineId),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBobinesCard(BuildContext context, ProductionSession session) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bobines utilisées',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...session.bobinesUtilisees.map(
              (bobine) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: bobine.estFinie
                    ? null
                    : theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                child: ListTile(
                  leading: Icon(
                    bobine.estFinie
                        ? Icons.check_circle
                        : Icons.rotate_right,
                    color: bobine.estFinie
                        ? Colors.green
                        : theme.colorScheme.primary,
                  ),
                  title: Text(bobine.bobineType),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Machine: ${bobine.machineName}'),
                      if (!bobine.estFinie)
                        Text(
                          'Bobine non finie - reste en machine',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.orange.shade700,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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
    final marginColor = marge.estRentable ? statusColors.success : statusColors.danger;
    return Card(
      color: marginColor.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(
          color: marginColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
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
            _buildInfoRow(context, 'Revenus totaux', '${marge.revenusTotaux} CFA'),
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
            _buildInfoRow(context, 'Nombre ventes', marge.nombreVentes.toString()),
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

  Widget _buildConsumptionInfoRow(BuildContext context, ProductionSession session) {
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
  const _ProductionSessionReportContent({
    required this.sessionId,
  });

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(productionSessionDetailProvider((sessionId)));
    
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
        onPrimaryAction: () => ref.invalidate(productionSessionDetailProvider((sessionId))),
      ),
    );
  }
}

