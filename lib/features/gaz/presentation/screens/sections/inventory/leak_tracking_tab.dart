import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import 'package:elyf_groupe_app/core/logging/app_logger.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/cylinder_leak.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:elyf_groupe_app/features/gaz/presentation/widgets/leak_report_dialog.dart';
import '../cylinder_leak/leak_filters.dart';
import '../cylinder_leak/leak_list_item.dart';

class LeakTrackingTab extends ConsumerStatefulWidget {
  const LeakTrackingTab({
    super.key,
    required this.enterpriseId,
    required this.moduleId,
  });

  final String enterpriseId;
  final String moduleId;

  @override
  ConsumerState<LeakTrackingTab> createState() => _LeakTrackingTabState();
}

class _LeakTrackingTabState extends ConsumerState<LeakTrackingTab> {
  LeakStatus? _filterStatus;

  void _showLeakDialog() {
    try {
      showDialog(
        context: context,
        builder: (context) => const LeakReportDialog(),
      ).then((result) {
        if (result == true && mounted) {
          ref.invalidate(
            cylinderLeaksProvider((
              enterpriseId: widget.enterpriseId,
              status: null,
            )),
          );
        }
      });
    } catch (e) {
      AppLogger.error(
        'Erreur lors de l\'ouverture du dialog de fuite: $e',
        name: 'gaz.inventory.leaks',
        error: e,
      );
      if (mounted) {
        NotificationService.showError(context, 'Erreur: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeEnterprise = ref.watch(activeEnterpriseProvider).value;
    final isPos = activeEnterprise?.isPointOfSale ?? false;

    final leaksAsync = ref.watch(
      cylinderLeaksProvider((
        enterpriseId: widget.enterpriseId,
        status: _filterStatus,
      )),
    );

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                ElyfButton(
                  onPressed: _showLeakDialog,
                  icon: Icons.add,
                  variant: ElyfButtonVariant.filled,
                  size: ElyfButtonSize.small,
                  child: const Text('Signaler une fuite'),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: LeakFilters(
            filterStatus: _filterStatus,
            onFilterChanged: (status) => setState(() => _filterStatus = status),
            showExchanged: !isPos,
          ),
        ),
        leaksAsync.when(
          data: (allLeaks) {
            final leaks = isPos 
                ? allLeaks.where((l) => l.status != LeakStatus.exchanged).toList() 
                : allLeaks;

            if (leaks.isEmpty) {
              return const SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.warning_outlined,
                  title: 'Aucune fuite enregistrée',
                  message: 'Toutes les bouteilles sont en bon état.',
                ),
              );
            }

            return SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              sliver: SliverList.separated(
                itemCount: leaks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    LeakListItem(leak: leaks[index]),
              ),
            );
          },
          loading: () => const SliverFillRemaining(
            child: LoadingIndicator(),
          ),
          error: (error, stackTrace) => SliverFillRemaining(
            child: ErrorDisplayWidget(
              error: error,
              title: 'Erreur de chargement',
              message: 'Impossible de charger les fuites de bouteilles.',
              onRetry: () => ref.refresh(
                cylinderLeaksProvider((
                  enterpriseId: widget.enterpriseId,
                  status: _filterStatus,
                )),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}
