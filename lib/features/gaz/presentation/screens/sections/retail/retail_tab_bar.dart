import 'package:flutter/material.dart';

/// Barre d'onglets personnalisée pour la vente au détail.
class RetailTabBar extends StatelessWidget {
  const RetailTabBar({
    super.key,
    required this.tabController,
  });

  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFFECECF0),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  tabController.animateTo(0);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: tabController.index == 0
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: tabController.index == 0
                        ? Border.all(
                            color: Colors.transparent,
                            width: 1.3,
                          )
                        : null,
                  ),
                  child: Text(
                    'Nouvelle Vente',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: const Color(0xFF0A0A0A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  tabController.animateTo(1);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: tabController.index == 1
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Mes Statistiques',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: const Color(0xFF0A0A0A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

