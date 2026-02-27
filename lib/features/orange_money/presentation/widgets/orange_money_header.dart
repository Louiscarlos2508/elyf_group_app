import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/app/theme/app_colors.dart';

/// A premium, professional header for the Orange Money module.
class OrangeMoneyHeader extends StatelessWidget {
  const OrangeMoneyHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.badgeText = 'ORANGE MONEY',
    this.badgeIcon = Icons.account_balance_wallet_rounded,
    this.additionalActions,
    this.bottom,
    this.asSliver = true,
  });

  final String title;
  final String subtitle;
  final String badgeText;
  final IconData badgeIcon;
  final List<Widget>? additionalActions;
  final Widget? bottom;
  final bool asSliver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets;
    final isKeyboardOpen = viewInsets.bottom > 0;

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
          colors: [
            AppColors.orangeMoneyGradient[0],
            AppColors.orangeMoneyGradient[1],
          ],
        ),
        borderRadius: BorderRadius.circular(isKeyboardOpen ? 16 : 24),
        boxShadow: [
          BoxShadow(
            color: AppColors.orangeMoneyGradient[0].withValues(alpha: 0.2),
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
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      badgeText,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              if (additionalActions != null)
                Row(mainAxisSize: MainAxisSize.min, children: additionalActions!),
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
          if (!isKeyboardOpen) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
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
