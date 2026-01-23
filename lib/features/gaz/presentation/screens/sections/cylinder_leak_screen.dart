import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import '../../../domain/entities/cylinder_leak.dart';
import '../../widgets/cylinder_leak_form_dialog.dart';
import 'cylinder_leak/leak_filters.dart';
import 'cylinder_leak/leak_header.dart';
import 'cylinder_leak/leak_list_item.dart';

/// Écran de gestion des bouteilles avec fuites.
class CylinderLeakScreen extends ConsumerStatefulWidget {
  const CylinderLeakScreen({
    super.key,
    required this.enterpriseId,
    required this.moduleId,
  });

  final String enterpriseId;
  final String moduleId;

  @override
  ConsumerState<CylinderLeakScreen> createState() => _CylinderLeakScreenState();
}

class _CylinderLeakScreenState extends ConsumerState<CylinderLeakScreen> {
  LeakStatus? _filterStatus;

  void _showLeakDialog() {
    try {
      showDialog(
        context: context,
        builder: (context) => CylinderLeakFormDialog(
          enterpriseId: widget.enterpriseId,
          moduleId: widget.moduleId,
        ),
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
      debugPrint('Erreur lors de l\'ouverture du dialog: $e');
      if (mounted) {
        NotificationService.showError(context, 'Erreur: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    final leaksAsync = ref.watch(
      cylinderLeaksProvider((
        enterpriseId: widget.enterpriseId,
        status: _filterStatus,
      )),
    );

    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: LeakHeader(isMobile: isMobile, onReportLeak: _showLeakDialog),
        ),
        // Filters
        SliverToBoxAdapter(
          child: LeakFilters(
            filterStatus: _filterStatus,
            onFilterChanged: (status) => setState(() => _filterStatus = status),
          ),
        ),
        leaksAsync.when(
          data: (leaks) {
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
