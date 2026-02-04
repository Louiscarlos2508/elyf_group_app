import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../../domain/entities/production_session.dart';
import '../../../domain/entities/production_session_status.dart';
import '../../widgets/production_sessions/production_sessions_card.dart';
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

    return Scaffold(
      body: sessionsAsync.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return CustomScrollView(
              slivers: [
                const SliverAppBar.large(
                  title: Text('Production'),
                  centerTitle: false,
                ),
                SliverFillRemaining(
                  child: SectionPlaceholder(
                    icon: Icons.factory_outlined,
                    title: 'Aucune session',
                    subtitle: 'Commencez par créer une nouvelle session',
                    primaryActionLabel: 'Nouvelle session',
                    onPrimaryAction: () => _showCreateForm(context),
                  ),
                ),
              ],
            );
          }

          // Filtrer les sessions annulées
          final filteredSessions = sessions.where(
            (s) => s.status != ProductionSessionStatus.cancelled,
          ).toList();

          if (filteredSessions.isEmpty) {
            return Center(
              child: SectionPlaceholder(
                icon: Icons.factory_outlined,
                title: 'Aucune session',
                subtitle: 'Commencez par créer une nouvelle session',
                primaryActionLabel: 'Nouvelle session',
                onPrimaryAction: () => _showCreateForm(context),
              ),
            );
          }

          // Trier les sessions par date (plus récentes en premier)
          final sessionsTriees = List<ProductionSession>.from(filteredSessions)
            ..sort((a, b) => b.date.compareTo(a.date));

          // Calculer les statistiques
          final totalSessions = sessionsTriees.length;
          final activeSessionsList = sessionsTriees
              .where(
                (s) =>
                    s.effectiveStatus == ProductionSessionStatus.started ||
                    s.effectiveStatus == ProductionSessionStatus.inProgress ||
                    s.effectiveStatus == ProductionSessionStatus.suspended ||
                    s.effectiveStatus == ProductionSessionStatus.draft,
              )
              .toList();
          final sessionsEnCours = activeSessionsList.length;
          final hasActiveSession = sessionsEnCours > 0;

          final sessionsTerminees = sessionsTriees
              .where(
                (s) => s.effectiveStatus == ProductionSessionStatus.completed,
              )
              .length;
          final totalProduit = sessionsTriees.fold<double>(
            0,
            (sum, s) => sum + s.quantiteProduite,
          );

          return Scaffold(
            body: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  title: const Text('Production'),
                  centerTitle: false,
                  pinned: true,
                  floating: true,
                  backgroundColor: theme.colorScheme.surface,
                  surfaceTintColor: theme.colorScheme.surface,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => ref.invalidate(productionSessionsStateProvider),
                      tooltip: 'Actualiser',
                    ),
                  ],
                ),
                
                // Statistiques (Dashboard Styled)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: ProductionSessionsStatistics(
                      totalSessions: totalSessions,
                      sessionsEnCours: sessionsEnCours,
                      sessionsTerminees: sessionsTerminees,
                      totalProduit: totalProduit,
                    ),
                  ),
                ),

                // Titre de section "Historique"
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          'SESSIONS RÉCENTES',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$totalSessions sessions',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Liste des sessions
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final session = sessionsTriees[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ProductionSessionsCard(session: session),
                      );
                    }, childCount: sessionsTriees.length),
                  ),
                ),
                
                // Espace pour le FAB
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
            floatingActionButton: !hasActiveSession
                ? FloatingActionButton.extended(
                    onPressed: () => _showCreateForm(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Nouvelle Session'),
                    elevation: 4,
                  )
                : null,
          );
        },
        loading: () => Scaffold(
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => Scaffold(
          body: Center(
            child: SectionPlaceholder(
              icon: Icons.error_outline,
              title: 'Erreur',
              subtitle: 'Impossible de charger les données',
              primaryActionLabel: 'Réessayer',
              onPrimaryAction: () => ref.invalidate(productionSessionsStateProvider),
            ),
          ),
        ),
      ),
    );
  }
}
