import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/tour.dart';
import '../widgets/tour_progress_bar.dart';
import '../../application/tour_notifier.dart';
import '../../../../core/theme/app_dimensions.dart';

class TourShell extends ConsumerWidget {
  final Widget child;
  final String tourId;

  const TourShell({super.key, required this.child, required this.tourId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(currentStepProvider(tourId));
    final truck = ref.watch(truckStateProvider(tourId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed('homeGaz');
            }
          },
          tooltip: 'Quitter la tournée',
        ),
        title: Text(
          'TOURNÉE', 
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: TourProgressBar(
            currentStatus: status,
            onStepTap: (newStatus) {
              if (newStatus != status) {
                context.goNamed(
                  newStatus.routeName, 
                  pathParameters: {'tourId': tourId},
                );
              }
            },
          ),
        ),
      ),
      body: child,
      // Dashboard FAB flottant pour voir l'état du camion à tout moment
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTruckDashboard(context, truck),
        icon: const Icon(Icons.summarize_outlined),
        label: const Text('ÉTAT DU CAMION'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  void _showTruckDashboard(BuildContext context, dynamic truck) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.r24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppDimensions.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('État du Camion', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppDimensions.s16),
            const Text('BOUTEILLES PLEINES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey)),
            const Divider(),
            ...truck.pleinesEnCamion.entries.map((e) => _DashboardRow(
              label: e.key.label,
              value: '${e.value}',
              icon: Icons.local_gas_station,
            )),
            if (truck.pleinesEnCamion.isEmpty) const Text('Aucune bouteille pleine', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
            const SizedBox(height: AppDimensions.s16),
            const Text('BOUTEILLES VIDES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey)),
            const Divider(),
            ...truck.videsEnCamion.entries.map((e) => _DashboardRow(
              label: e.key.label,
              value: '${e.value}',
              icon: Icons.inventory_2_outlined,
            )),
            if (truck.videsEnCamion.isEmpty) const Text('Aucun vide collecté', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
            const Divider(),
            _DashboardRow(label: 'Total Pleines', value: '${truck.totalPleines}', icon: Icons.straighten, isBold: true),
            _DashboardRow(label: 'Total Vides', value: '${truck.totalVides}', icon: Icons.straighten, isBold: true),
            _DashboardRow(label: 'Cash en main', value: '${truck.cashEncaisse} FCFA', icon: Icons.payments, isBold: true),
          ],
        ),
      ),
    );
  }
}

class _DashboardRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isBold;

  const _DashboardRow({required this.label, required this.value, required this.icon, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey, size: 20),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w500)),
          const Spacer(),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isBold ? 16 : 14)),
        ],
      ),
    );
  }
}
