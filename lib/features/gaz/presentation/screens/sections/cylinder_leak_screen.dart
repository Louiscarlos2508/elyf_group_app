import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/cylinder_leak.dart';
import '../../widgets/cylinder_leak_form_dialog.dart';
import 'cylinder_leak/leak_empty_state.dart';
import 'cylinder_leak/leak_filters.dart';
import 'cylinder_leak/leak_header.dart';
import 'cylinder_leak/leak_list_item.dart';

/// Écran de gestion des bouteilles avec fuites.
class CylinderLeakScreen extends ConsumerStatefulWidget {
  const CylinderLeakScreen({super.key});

  @override
  ConsumerState<CylinderLeakScreen> createState() =>
      _CylinderLeakScreenState();
}

class _CylinderLeakScreenState extends ConsumerState<CylinderLeakScreen> {
  String? _enterpriseId;
  LeakStatus? _filterStatus;

  void _showLeakDialog() {
    try {
      showDialog(
        context: context,
        builder: (context) => const CylinderLeakFormDialog(),
      ).then((result) {
        if (result == true && mounted) {
          ref.invalidate(
            cylinderLeaksProvider(
              (enterpriseId: _enterpriseId!, status: null),
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('Erreur lors de l\'ouverture du dialog: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    // TODO: Récupérer enterpriseId depuis le contexte/tenant
    _enterpriseId ??= 'default_enterprise';

    final leaksAsync = ref.watch(
      cylinderLeaksProvider(
        (enterpriseId: _enterpriseId!, status: _filterStatus),
      ),
    );

    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: LeakHeader(
            isMobile: isMobile,
            onReportLeak: _showLeakDialog,
          ),
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
                child: LeakEmptyState(),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              sliver: SliverList.separated(
                itemCount: leaks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => LeakListItem(leak: leaks[index]),
              ),
            );
          },
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => SliverFillRemaining(
            child: Center(child: Text('Erreur: $e')),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}
