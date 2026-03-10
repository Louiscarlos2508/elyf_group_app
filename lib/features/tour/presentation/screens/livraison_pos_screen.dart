import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../widgets/quantity_counter.dart';
import '../../application/tour_notifier.dart';
import '../../data/models/tour.dart';
import '../../data/models/livraison_entry.dart';

class LivraisonPosScreen extends ConsumerStatefulWidget {
  final String tourId;
  final String siteId;
  final String siteName;

  const LivraisonPosScreen({super.key, required this.tourId, required this.siteId, required this.siteName});

  @override
  ConsumerState<LivraisonPosScreen> createState() => _LivraisonPosScreenState();
}

class _LivraisonPosScreenState extends ConsumerState<LivraisonPosScreen> {
  final Map<FormatBouteille, int> _counts = {};
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formats = ref.watch(formatsActifsProvider);
    final truckState = ref.watch(truckStateProvider(widget.tourId));

    if (!_initialized && formats.isNotEmpty) {
      for (var f in formats) {
        _counts[f] = truckState.pleinesEnCamion[f] ?? 0;
      }
      _initialized = true;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ravitaillement POS')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.s16),
            child: Text(
              'Déposer des bouteilles pleines au Point de Vente',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppDimensions.s16),
              itemCount: formats.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.s16),
              itemBuilder: (context, index) {
                final format = formats[index];
                return QuantityCounter(
                  label: format.label,
                  value: _counts[format] ?? 0,
                  onChanged: (val) => setState(() => _counts[format] = val),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.s16),
              child: FilledButton(
                onPressed: _hasData ? _handleSave : null,
                child: const Text('VALIDER LE DEPÔT'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _hasData => _counts.values.any((v) => v > 0);

  void _handleSave() {
    final entry = LivraisonEntry(
      siteId: widget.siteId,
      siteName: widget.siteName,
      typeSite: TypeSite.pos,
      lignes: _counts.entries
          .where((e) => e.value > 0)
          .map((e) => LivraisonLigne(format: e.key, quantiteLivree: e.value, prixUnitaire: 0)) // Pas de cash direct au POS
          .toList(),
      montantEncaisse: 0, // Les POS vendent eux-mêmes, le gérant ne récupère pas d'argent ici
      timestamp: DateTime.now(),
    );

    ref.read(tourNotifierProvider(widget.tourId).notifier).addLivraison(entry);
    context.pop();
  }
}
