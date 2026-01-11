import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../../domain/entities/production_session.dart';
import '../../widgets/production_tracking/production_tracking_progress.dart';
import '../../widgets/production_tracking/production_tracking_session_info.dart';
import '../../widgets/production_tracking/tracking_step_content.dart';
import 'production_session_form_screen.dart';

/// Écran de suivi de production en temps réel avec progression dynamique.
class ProductionTrackingScreen extends ConsumerStatefulWidget {
  const ProductionTrackingScreen({
    super.key,
    required this.sessionId,
  });

  final String sessionId;

  @override
  ConsumerState<ProductionTrackingScreen> createState() =>
      _ProductionTrackingScreenState();
}

class _ProductionTrackingScreenState
    extends ConsumerState<ProductionTrackingScreen> {
  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(
      productionSessionDetailProvider((widget.sessionId)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi de production'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              sessionAsync.whenData((session) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ProductionSessionFormScreen(
                      session: session,
                    ),
                  ),
                );
              });
            },
          ),
        ],
      ),
      body: sessionAsync.when(
        data: (session) => _ProductionTrackingContent(session: session),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erreur: $error'),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductionTrackingContent extends ConsumerWidget {
  const _ProductionTrackingContent({required this.session});

  final ProductionSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = session.effectiveStatus;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: ProductionTrackingProgress(status: status),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              TrackingStepContent(session: session, status: status),
              const SizedBox(height: 24),
              ProductionTrackingSessionInfo(session: session),
            ]),
          ),
        ),
      ],
    );
  }
}
