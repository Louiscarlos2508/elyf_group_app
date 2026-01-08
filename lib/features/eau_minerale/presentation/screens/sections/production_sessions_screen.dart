import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../../domain/entities/production_session.dart';
import '../../../domain/entities/production_session_status.dart';
import '../../../domain/entities/sale.dart';
import '../../widgets/production_sessions/production_sessions_card.dart';
import '../../widgets/production_sessions/production_sessions_header.dart';
import '../../widgets/production_sessions/production_sessions_statistics.dart';
import '../../widgets/section_placeholder.dart';
import 'production_session_form_screen.dart';

/// Écran de liste des sessions de production.
class ProductionSessionsScreen extends ConsumerWidget {
  const ProductionSessionsScreen({super.key});

  void _showCreateForm(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProductionSessionFormScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(productionSessionsStateProvider);
    final theme = Theme.of(context);

    return sessionsAsync.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return SectionPlaceholder(
              icon: Icons.factory_outlined,
              title: 'Aucune session de production',
              subtitle: 'Créez une nouvelle session pour commencer',
              primaryActionLabel: 'Nouvelle session',
              onPrimaryAction: () => _showCreateForm(context),
            );
          }

          // Trier les sessions par date (plus récentes en premier)
          final sessionsTriees = List<ProductionSession>.from(sessions)
            ..sort((a, b) => b.date.compareTo(a.date));

          // Calculer les statistiques
          final totalSessions = sessionsTriees.length;
          final sessionsEnCours = sessionsTriees.where((s) =>
            s.effectiveStatus == ProductionSessionStatus.started ||
            s.effectiveStatus == ProductionSessionStatus.inProgress
          ).length;
          final sessionsTerminees = sessionsTriees.where((s) =>
            s.effectiveStatus == ProductionSessionStatus.completed
          ).length;
          final totalProduit = sessionsTriees.fold<double>(
            0,
            (sum, s) => sum + s.quantiteProduite,
          );

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProductionSessionsHeader(
                        totalSessions: totalSessions,
                        onCreateSession: () => _showCreateForm(context),
                      ),
                      const SizedBox(height: 24),
                      ProductionSessionsStatistics(
                        totalSessions: totalSessions,
                        sessionsEnCours: sessionsEnCours,
                        sessionsTerminees: sessionsTerminees,
                        totalProduit: totalProduit,
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final session = sessionsTriees[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ProductionSessionsCard(session: session),
                      );
                    },
                    childCount: sessionsTriees.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 24),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => SectionPlaceholder(
          icon: Icons.error_outline,
          title: 'Erreur de chargement',
          subtitle: 'Impossible de charger les sessions de production.',
          primaryActionLabel: 'Réessayer',
          onPrimaryAction: () => ref.invalidate(productionSessionsStateProvider),
        ),
    );
  }
}

