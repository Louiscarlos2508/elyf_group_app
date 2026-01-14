import 'package:flutter/material.dart';

/// Grid layout for displaying KPI items responsively.
class KpiGrid extends StatelessWidget {
  const KpiGrid({super.key, required this.items});

  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        if (isWide) {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.5,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) => items[index],
          );
        } else {
          return Column(
            children: items
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: item,
                  ),
                )
                .toList(),
          );
        }
      },
    );
  }
}
