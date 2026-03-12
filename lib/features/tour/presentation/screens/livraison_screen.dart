import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../application/tour_notifier.dart';
import '../../data/models/tour.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/features/administration/application/providers.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'frais_screen.dart';

class LivraisonScreen extends ConsumerStatefulWidget {
  final String tourId;

  const LivraisonScreen({super.key, required this.tourId});

  @override
  ConsumerState<LivraisonScreen> createState() => _LivraisonScreenState();
}

class _LivraisonScreenState extends ConsumerState<LivraisonScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tourNotifierProvider(widget.tourId)).value;

    if (state == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: AppBar(
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'GROSSISTES'),
              Tab(text: 'POINTS DE VENTE'),
              Tab(text: 'DÉPENSES'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SiteList(
            sites: _getSites(TypeSite.grossiste),
            tourId: widget.tourId,
            routePrefix: 'livraison-grossiste',
          ),
          _SiteList(
            sites: _getSites(TypeSite.pos),
            tourId: widget.tourId,
            routePrefix: 'livraison-pos',
          ),
          FraisScreen(tourId: widget.tourId),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.s16),
          child: FilledButton(
            onPressed: state.livraisons.isNotEmpty 
                ? () => ref.read(tourNotifierProvider(widget.tourId).notifier).startClosing().then((_) {
                    if (context.mounted) {
                      context.goNamed('cloture', pathParameters: {'tourId': widget.tourId});
                    }
                  })
                : null,
            child: const Text('ALLER AU BILAN FINAL'),
          ),
        ),
      ),
    );
  }

  List<Site> _getSites(TypeSite type) {
    if (type == TypeSite.grossiste) {
      final wholesalers = ref.watch(wholesalersProvider).value ?? [];
      return wholesalers.map((w) => Site(
        id: w.id, 
        nom: w.name, 
        adresse: w.address ?? '', 
        telephone: w.phone ?? '', 
        type: TypeSite.grossiste,
      )).toList();
    } else {
      final activeEnterprise = ref.watch(activeEnterpriseProvider).value;
      final posList = ref.watch(enterprisesByParentAndTypeProvider((
        parentId: activeEnterprise?.id ?? '',
        type: EnterpriseType.gasPointOfSale,
      ))).value ?? [];
      
      return posList.map((p) => Site(
        id: p.id, 
        nom: p.name, 
        adresse: p.address ?? '', 
        telephone: '',
        type: TypeSite.pos,
      )).toList();
    }
  }
}

class _SiteList extends ConsumerWidget {
  final List<Site> sites;
  final String tourId;
  final String routePrefix;

  const _SiteList({required this.sites, required this.tourId, required this.routePrefix});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tourNotifierProvider(tourId)).value;
    
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.s16),
      itemCount: sites.length,
      itemBuilder: (context, index) {
        final site = sites[index];
        final isDone = state?.livraisons.any((l) => l.siteId == site.id) ?? false;

        return Card(
          margin: const EdgeInsets.only(bottom: AppDimensions.s12),
          child: ListTile(
            title: Text(site.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(site.adresse),
            trailing: isDone 
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.chevron_right),
            onTap: () => context.pushNamed(
              routePrefix,
              pathParameters: {'tourId': tourId, 'siteId': site.id},
              extra: {'name': site.nom},
            ),
          ),
        );
      },
    );
  }
}
