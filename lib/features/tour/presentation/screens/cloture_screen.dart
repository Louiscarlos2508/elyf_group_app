import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../application/tour_notifier.dart';
import '../../data/models/tour.dart';
import '../../../../core/services/sunmi_print_service.dart';
import '../../data/models/bilan_tour.dart';
import 'package:elyf_groupe_app/core/auth/providers.dart';

class ClotureScreen extends ConsumerWidget {
  final String tourId;

  const ClotureScreen({super.key, required this.tourId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bilanAsync = ref.watch(enhancedBilanProvider(tourId));
    
    return Scaffold(
      body: bilanAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (bilan) {
          if (bilan == null) return const Center(child: Text('Bilan introuvable'));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Bilan Final du Tour',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.s24),

                _BilanSection(
                  title: 'FLUX FINANCIER',
                  items: [
                    _BilanRow(label: 'Ventes Sites', value: Formatters.formatCurrency(bilan.totalEncaisse), isPositive: true),
                    if (bilan.postClosureCash != 0)
                      _BilanRow(label: 'Encaissements Post-Tour', value: Formatters.formatCurrency(bilan.postClosureCash), isPositive: true),
                    _BilanRow(label: 'Coût Recharge', value: '- ${Formatters.formatCurrency(bilan.coutRecharge)}', isNegative: true),
                    _BilanRow(label: 'Dépenses Trajet', value: '- ${Formatters.formatCurrency(bilan.totalFrais)}', isNegative: true),
                  ],
                  footer: _BilanRow(
                    label: 'RÉSULTAT NET', 
                    value: Formatters.formatCurrency(bilan.resultatNet),
                    isHighlight: true,
                    isPositive: bilan.resultatNet >= 0,
                    isNegative: bilan.resultatNet < 0,
                  ),
                ),

                const SizedBox(height: AppDimensions.s16),

                _BilanSection(
                  title: 'DÉTAIL PAR SITE',
                  items: bilan.siteBreakdowns.map((s) => _SiteBilanRow(site: s)).toList(),
                  footer: _BilanRow(
                    label: 'TOTAL FLUX', 
                    value: 'E: ${bilan.totalVidesCollectes} / S: ${bilan.totalPleinesLivrees}', 
                    isHighlight: true,
                  ),
                ),

                if (bilan.postClosureLeaks > 0) ...[
                  const SizedBox(height: AppDimensions.s16),
                  _BilanSection(
                    title: 'SIGNALEMENTS POST-TOUR',
                    items: [
                      _BilanRow(label: 'Fuites Détectées', value: '${bilan.postClosureLeaks}', isNegative: true),
                    ],
                    footer: const SizedBox.shrink(),
                  ),
                ],

                const SizedBox(height: AppDimensions.s32),

                OutlinedButton.icon(
                  onPressed: () => _printReport(ref, bilan),
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('IMPRIMER RAPPORT DE TOURNÉE'),
                ),

                const SizedBox(height: AppDimensions.s12),
                if (ref.watch(tourNotifierProvider(tourId)).value?.status != TourStatus.closed)
                  FilledButton.icon(
                    onPressed: () => _handleFinalClosure(ref, context),
                    icon: const Icon(Icons.lock_outline),
                    label: const Text('CLÔTURER DÉFINITIVEMENT'),
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.s16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.r12),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'TOUR CLÔTURÉ',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppDimensions.s48),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _printReport(WidgetRef ref, BilanTour bilan) async {
    final userName = ref.read(currentUserProvider).value?.displayName ?? "Gérant";
    
    await SunmiPrintService.instance.printTourBilan(
      driverName: userName,
      bilan: bilan,
      date: DateTime.now(),
    );
  }

  void _handleFinalClosure(WidgetRef ref, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la clôture ?'),
        content: const Text('Une fois clôturé, vous ne pourrez plus modifier les données de ce tour.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ANNULER')),
          TextButton(
            onPressed: () async {
              // On ferme le dialogue de confirmation
              Navigator.pop(context);
              
              // On affiche un indicateur de chargement bloquant
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );

              try {
                  await ref.read(tourNotifierProvider(tourId).notifier).validateClosure();
                if (context.mounted) {
                  // Fermer le chargement (utiliser rootNavigator pour être sûr de cibler le dialogue)
                  Navigator.of(context, rootNavigator: true).pop(); 
                  context.goNamed('homeGaz');
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // Fermer le chargement
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur lors de la clôture: $e')),
                  );
                }
              }
            },
            child: const Text('OUI, CLÔTURER'),
          ),
        ],
      ),
    );
  }
}

class _SiteBilanRow extends StatelessWidget {
  final SiteBilan site;

  const _SiteBilanRow({required this.site});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(site.siteName, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('E: ${site.totalEntrees} / S: ${site.totalSorties}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              Text(Formatters.formatCurrency(site.encaissement), style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BilanSection extends StatelessWidget {
  final String title;
  final List<Widget> items;
  final Widget footer;

  const _BilanSection({required this.title, required this.items, required this.footer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(title, style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 1.2, color: Colors.grey)),
          ),
          ...items,
          const Divider(height: 1),
          footer,
        ],
      ),
    );
  }
}

class _BilanRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;
  final bool isPositive;
  final bool isNegative;

  const _BilanRow({
    required this.label, 
    required this.value, 
    this.isHighlight = false,
    this.isPositive = false,
    this.isNegative = false,
  });

  @override
  Widget build(BuildContext context) {

    Color? valueColor;
    if (isPositive) valueColor = Colors.green[700];
    if (isNegative) valueColor = Colors.red[700];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal)),
          Text(
            value, 
            style: TextStyle(
              fontWeight: isHighlight ? FontWeight.w900 : FontWeight.bold,
              fontSize: isHighlight ? 16 : 14,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
