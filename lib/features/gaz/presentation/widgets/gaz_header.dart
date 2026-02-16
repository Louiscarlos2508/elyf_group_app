import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import '../../application/providers.dart';
import '../../../../shared/utils/currency_formatter.dart';
import 'package:intl/intl.dart';

/// A premium header widget for the Gaz module, following the project's standardized design.
class GazHeader extends ConsumerWidget {
  const GazHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.gradientColors = const [Color(0xFF3B82F6), Color(0xFF1D4ED8)], // Blue default for Gaz
    this.shadowColor,
    this.additionalActions,
    this.bottom,
    this.asSliver = true,
  });

  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final Color? shadowColor;
  final List<Widget>? additionalActions;
  final Widget? bottom;
  final bool asSliver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeEnterprise = ref.watch(activeEnterpriseProvider).value;
    final activeSessionAsync = ref.watch(activeGazSessionProvider);

    final content = Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gradientColors.first,
            const Color(0xFF60A5FA), // Lighter blue for depth
            gradientColors.last,
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: (shadowColor ?? gradientColors.last).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        activeEnterprise?.name.toUpperCase() ?? title.toUpperCase(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      subtitle,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              if (additionalActions != null) ...[
                const SizedBox(width: 16),
                ...additionalActions!,
              ],
            ],
          ),

          // Session Accountability Bar (Story 5.1)
          const SizedBox(height: 24),
          activeSessionAsync.when(
            data: (session) {
              if (session == null) return _buildNoSessionBadge(theme);
              return _buildSessionInfoBar(theme, session);
            },
            loading: () => _buildSessionShimmer(theme),
            error: (_, __) => const SizedBox.shrink(),
          ),

          if (bottom != null) ...[
            const SizedBox(height: 24),
            bottom!,
          ],
        ],
      ),
    );

    if (asSliver) {
      return SliverToBoxAdapter(child: content);
    }
    return content;
  }

  Widget _buildNoSessionBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Text(
            'AUCUNE SESSION ACTIVE',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionInfoBar(ThemeData theme, dynamic session) {
    final dateFormat = DateFormat('HH:mm');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          _buildInfoItem(
            theme,
            'STATUT',
            'OUVERTE',
            Icons.check_circle_outline,
            Colors.greenAccent,
          ),
          _buildDivider(),
          _buildInfoItem(
            theme,
            'DEPUIS',
            dateFormat.format(session.openedAt),
            Icons.access_time,
            Colors.white,
          ),
          _buildDivider(),
          _buildInfoItem(
            theme,
            'CASH THÉO.',
            CurrencyFormatter.formatDouble(session.theoreticalCash),
            Icons.account_balance_wallet_outlined,
            Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color valueColor,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: Colors.white60),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white60,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 32,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.white.withValues(alpha: 0.1),
    );
  }

  Widget _buildSessionShimmer(ThemeData theme) {
    return Container(
      height: 64,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

