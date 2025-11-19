import 'package:flutter/material.dart';

class ModuleHomeScaffold extends StatelessWidget {
  const ModuleHomeScaffold({
    super.key,
    required this.title,
    required this.enterpriseId,
  });

  final String title;
  final String enterpriseId;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              enterpriseId,
              style: textTheme.labelLarge?.copyWith(
                color: colors.primary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
