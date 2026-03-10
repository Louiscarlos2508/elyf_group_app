import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../widgets/quantity_counter.dart';
import '../../application/tour_notifier.dart';
import '../../data/models/tour.dart';
import '../../data/models/collecte_entry.dart';

class CollecteSiteScreen extends ConsumerStatefulWidget {
  const CollecteSiteScreen({
    super.key,
    required this.tourId,
    required this.siteId,
    required this.siteType,
    required this.siteName,
  });

  final String tourId;
  final String siteId;
  final String siteName;
  final TypeSite siteType;

  @override
  ConsumerState<CollecteSiteScreen> createState() => _CollecteSiteScreenState();
}

class _CollecteSiteScreenState extends ConsumerState<CollecteSiteScreen> {
  final Map<FormatBouteille, int> _counts = {};
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formats = ref.watch(formatsActifsProvider);
    final state = ref.watch(tourNotifierProvider(widget.tourId)).value;

    // Initialiser les comptes avec l'existant si possible
    if (!_initialized && state != null && formats.isNotEmpty) {
      final existing = state.collectes.where((c) => c.siteId == widget.siteId).firstOrNull;
      if (existing != null) {
        _counts.addAll(existing.quantitesVides);
      } else {
        for (var f in formats) {
          _counts[f] = 0;
        }
      }
      _initialized = true;
    }

    if (formats.isEmpty) return const Scaffold(body: Center(child: Text('Aucun format configuré')));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enregistrer Collecte'),
      ),
      body: Column(
        children: [
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
                child: const Text('VALIDER LA COLLECTE'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _hasData => _counts.values.any((v) => v > 0);

  void _handleSave() {
    final entry = CollecteEntry(
      siteId: widget.siteId,
      siteName: widget.siteName,
      siteType: widget.siteType,
      quantitesVides: Map.from(_counts)..removeWhere((k, v) => v == 0),
      timestamp: DateTime.now(),
    );

    ref.read(tourNotifierProvider(widget.tourId).notifier).addCollecte(entry);
    context.pop();
  }
}
