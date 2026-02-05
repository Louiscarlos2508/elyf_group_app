import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AppShimmers {
  static Widget card(BuildContext context, {double height = 100}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Card(
        child: Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  static Widget listTile(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  static Widget form(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: const _FormShimmer(),
    );
  }

  static Widget list(BuildContext context, {int itemCount = 5}) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => listTile(context),
    );
  }

  static Widget statsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      padding: const EdgeInsets.all(16),
      children: [
        card(context),
        card(context),
        card(context),
        card(context),
      ],
    );
  }

  static Widget grid(BuildContext context, {int count = 4}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      padding: const EdgeInsets.all(16),
      itemCount: count,
      itemBuilder: (context, index) => card(context),
    );
  }

  static Widget table(BuildContext context, {int rows = 5}) {
    return Column(
      children: List.generate(
        rows,
        (index) => Column(
          children: [
            listTile(context),
            const Divider(height: 1),
          ],
        ),
      ),
    );
  }

  static Widget chart(BuildContext context, {double height = 200}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
        child: Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: CustomPaint(
            painter: _ChartShimmerPainter(),
          ),
        ),
      ),
    );
  }
}

class _ChartShimmerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.lineTo(size.width * 0.2, size.height * 0.4);
    path.lineTo(size.width * 0.4, size.height * 0.6);
    path.lineTo(size.width * 0.6, size.height * 0.3);
    path.lineTo(size.width * 0.8, size.height * 0.5);
    path.lineTo(size.width, size.height * 0.2);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _FormShimmer extends StatelessWidget {
  const _FormShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimmerField(context),
          const SizedBox(height: 24),
          _shimmerField(context),
          const SizedBox(height: 24),
          _shimmerField(context),
          const SizedBox(height: 32),
          AppShimmers.card(context, height: 48), // Submit button
        ],
      ),
    );
  }

  Widget _shimmerField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 16,
          width: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        AppShimmers.card(context, height: 56),
      ],
    );
  }
}
