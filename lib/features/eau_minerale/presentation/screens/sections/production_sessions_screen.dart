import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../../domain/entities/production_session.dart';
import '../../../domain/entities/production_session_status.dart';
import '../../widgets/production_sessions/production_sessions_card.dart';
import '../../widgets/production_sessions/production_sessions_statistics.dart';
import '../../widgets/section_placeholder.dart';
import 'production_session_form_screen.dart';

import 'package:elyf_groupe_app/shared/presentation/widgets/elyf_ui/atoms/elyf_background.dart';

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
              return _buildEmptyState(context, theme);
            }

            // Filtrer les sessions annulées
            final filteredSessions = sessions.where(
              (s) => s.status != ProductionSessionStatus.cancelled,
            ).toList();

            if (filteredSessions.isEmpty) {
              return _buildEmptyState(context, theme);
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

            return Stack(
              children: [
                CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Premium Header
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF0284C7), // Sky 600
                              Color(0xFF00C2FF), // Custom Cyan
                              Color(0xFF0369A1), // Sky 700
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "EAU MINÉRALE",
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Production",
                                    style: theme.textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh, color: Colors.white),
                              onPressed: () => ref.invalidate(productionSessionsStateProvider),
                              tooltip: 'Actualiser',
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Statistiques (Dashboard Styled)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      sliver: SliverToBoxAdapter(
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
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
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
                            padding: const EdgeInsets.only(bottom: 16),
                            child: ProductionSessionsCard(session: session),
                          );
                        }, childCount: sessionsTriees.length),
                      ),
                    ),
                    
                    // Espace pour le FAB
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
                
                if (!hasActiveSession)
                  Positioned(
                    bottom: 24,
                    right: 24,
                    child: FloatingActionButton.extended(
                      onPressed: () => _showCreateForm(context),
                      icon: const Icon(Icons.add_task),
                      label: const Text('Nouvelle Session'),
                      elevation: 6,
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: SectionPlaceholder(
              icon: Icons.error_outline,
              title: 'Erreur',
              subtitle: 'Impossible de charger les données',
              primaryActionLabel: 'Réessayer',
              onPrimaryAction: () => ref.invalidate(productionSessionsStateProvider),
            ),
          ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "EAU MINÉRALE",
                  style: theme.textTheme.labelLarge?.copyWith(color: Colors.white70),
                ),
                Text(
                  "Production",
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverFillRemaining(
          child: SectionPlaceholder(
            icon: Icons.factory_outlined,
            title: 'Aucune session',
            subtitle: 'Commencez par créer une nouvelle session de production',
            primaryActionLabel: 'Nouvelle session',
            onPrimaryAction: () => _showCreateForm(context),
          ),
        ),
      ],
    );
  }
}
