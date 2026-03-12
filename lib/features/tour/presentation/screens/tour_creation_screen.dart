import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../application/tour_notifier.dart';

class TourCreationScreen extends ConsumerStatefulWidget {
  const TourCreationScreen({super.key});

  @override
  ConsumerState<TourCreationScreen> createState() => _TourCreationScreenState();
}

class _TourCreationScreenState extends ConsumerState<TourCreationScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau Tour'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.s24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.local_shipping_outlined, size: 80, color: Colors.blueGrey),
              const SizedBox(height: AppDimensions.s24),
              Text(
                'Configuration du départ',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.s32),
              
              // Date (Read only)
              TextFormField(
                initialValue: DateTime.now().toString().split(' ')[0], // Simplifié
                decoration: const InputDecoration(
                  labelText: 'Date du Tour',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
              ),
              const SizedBox(height: AppDimensions.s40),

              FilledButton.icon(
                onPressed: _handleStart,
                icon: const Icon(Icons.play_arrow),
                label: const Text('DEMARRER LE TOUR'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleStart() async {
    if (_formKey.currentState!.validate()) {
      try {
        // 1. Initialiser le notifier (création persistante)
        await ref.read(tourNotifierProvider('').notifier).startTour();
        
        // 2. Récupérer l'état mis à jour
        final state = ref.read(tourNotifierProvider('')).value;
        if (state != null && state.tourId.isNotEmpty) {
           // 3. Naviguer vers la première étape réelle
          if (mounted) {
            context.goNamed('collecte', pathParameters: {'tourId': state.tourId});
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de la création du tour: $e')),
          );
        }
      }
    }
  }
}
