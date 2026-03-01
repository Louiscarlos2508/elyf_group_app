import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/tenant/tenant_provider.dart';
import '../../../../../features/administration/domain/entities/enterprise.dart';
import '../../../../../app/theme/app_colors.dart';

/// A professional, dynamic header that adapts to the active module and enterprise.
/// Replaces static headers and AppBars on main screens.
class ElyfModuleHeader extends ConsumerWidget {
  const ElyfModuleHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.module,
    this.enterpriseName,
    this.actions,
    this.bottom,
    this.showBackButton = false,
    this.asSliver = true,
  });

  final String title;
  final String? subtitle;
  final EnterpriseModule? module;
  final String? enterpriseName;
  final List<Widget>? actions;
  final Widget? bottom;
  final bool showBackButton;
  final bool asSliver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeEnterprise = ref.watch(activeEnterpriseProvider).value;
    
    final effectiveModule = module ?? activeEnterprise?.type.module ?? EnterpriseModule.group;
    final effectiveEnterpriseName = enterpriseName ?? activeEnterprise?.name ?? 'ELYF Groupe';
    
    final viewInsets = MediaQuery.of(context).viewInsets;
    final isKeyboardOpen = viewInsets.bottom > 0;

    // Determine gradient based on module
    List<Color> gradientColors;
    switch (effectiveModule) {
      case EnterpriseModule.mobileMoney:
        gradientColors = AppColors.orangeMoneyGradient;
        break;
      case EnterpriseModule.eau:
        gradientColors = AppColors.waterGradient;
        break;
      case EnterpriseModule.gaz:
        gradientColors = [const Color(0xFFFF6B00), const Color(0xFFFF9E00)];
        break;
      case EnterpriseModule.immobilier:
        gradientColors = [const Color(0xFF6B4226), const Color(0xFF8B5A2B)];
        break;
      case EnterpriseModule.boutique:
        gradientColors = [const Color(0xFF1B5E20), const Color(0xFF4CAF50)];
        break;
      default:
        gradientColors = AppColors.mainGradient;
    }

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.fromLTRB(
        14, 
        isKeyboardOpen ? 4 : 14, 
        14, 
        isKeyboardOpen ? 4 : 6
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 24, 
        vertical: isKeyboardOpen ? 12 : 22
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(isKeyboardOpen ? 16 : 24),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.2),
            blurRadius: isKeyboardOpen ? 10 : 16,
            offset: Offset(0, isKeyboardOpen ? 4 : 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Badge Module + Enterprise
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showBackButton) ...[
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(effectiveModule.icon, color: Colors.white, size: 14),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '${effectiveModule.label.toUpperCase()} • $effectiveEnterpriseName',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (actions != null)
                Row(mainAxisSize: MainAxisSize.min, children: actions!),
            ],
          ),
          SizedBox(height: isKeyboardOpen ? 12 : 20),
          Text(
            title,
            style: (isKeyboardOpen ? theme.textTheme.titleMedium : theme.textTheme.headlineSmall)?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              height: 1.1,
              fontFamily: 'Outfit',
            ),
          ),
          if (subtitle != null && !isKeyboardOpen) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ],
          if (bottom != null) ...[
            SizedBox(height: isKeyboardOpen ? 12 : 20),
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
}
