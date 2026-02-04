import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AdminShimmers {
  static Widget statsShimmer(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _shimmerCard(context)),
              const SizedBox(width: 16),
              Expanded(child: _shimmerCard(context)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _shimmerCard(context)),
              const SizedBox(width: 16),
              Expanded(child: _shimmerCard(context)),
            ],
          ),
        ],
      ),
    );
  }

  static Widget enterpriseListShimmer(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (context, index) => _shimmerListTile(context),
    );
  }

  static Widget _shimmerCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Card(
        child: Container(
          height: 100,
          padding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  static Widget _shimmerListTile(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Shimmer.fromColors(
        baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
