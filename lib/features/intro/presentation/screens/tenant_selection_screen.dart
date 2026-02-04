import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/tenant/tenant_provider.dart';

/// Professional tenant selection screen with premium UI
class TenantSelectionScreen extends ConsumerWidget {
  const TenantSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final accessibleEnterprisesAsync = ref.watch(
      userAccessibleEnterprisesProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sélection d\'entreprise'),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.primary.withValues(alpha: 0.05),
              colors.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: accessibleEnterprisesAsync.when(
            data: (enterprises) {
              if (enterprises.isEmpty) {
                return _buildEmptyState(context, colors, textTheme);
              }

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sélectionnez votre',
                            style: textTheme.headlineMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          Text(
                            'Entreprise',
                            style: textTheme.displaySmall?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${enterprises.length} ${enterprises.length > 1 ? 'entreprises accessibles' : 'entreprise accessible'}',
                            style: textTheme.bodyLarge?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final enterprise = enterprises[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _EnterpriseCard(
                              enterprise: enterprise,
                              onTap: () async {
                                // Set active enterprise
                                final tenantNotifier = ref.read(
                                  activeEnterpriseIdProvider.notifier,
                                );
                                await tenantNotifier.setActiveEnterpriseId(
                                  enterprise.id,
                                );

                                // Navigate to modules
                                if (context.mounted) {
                                  context.go('/modules');
                                }
                              },
                            ),
                          );
                        },
                        childCount: enterprises.length,
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => _buildLoadingState(context, colors),
            error: (error, stack) => _buildErrorState(
              context,
              colors,
              textTheme,
              error.toString(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Chargement des entreprises...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ColorScheme colors,
    TextTheme textTheme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_outlined,
              size: 80,
              color: colors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucune entreprise accessible',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Contactez votre administrateur pour obtenir l\'accès à une entreprise.',
              style: textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    ColorScheme colors,
    TextTheme textTheme,
    String error,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: colors.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Erreur de chargement',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EnterpriseCard extends StatefulWidget {
  const _EnterpriseCard({
    required this.enterprise,
    required this.onTap,
  });

  final dynamic enterprise;
  final VoidCallback onTap;

  @override
  State<_EnterpriseCard> createState() => _EnterpriseCardState();
}

class _EnterpriseCardState extends State<_EnterpriseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _controller.forward().then((_) {
              _controller.reverse();
              widget.onTap();
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: 0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colors.primary,
                          colors.primary.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.business_rounded,
                      color: colors.onPrimary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.enterprise.name,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (widget.enterprise.description != null &&
                            widget.enterprise.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.enterprise.description!,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: colors.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
