import 'package:flutter/material.dart';

import '../widgets/module_home_scaffold.dart';

class GazHomeScreen extends StatelessWidget {
  const GazHomeScreen({super.key, required this.enterpriseId});

  final String enterpriseId;

  @override
  Widget build(BuildContext context) {
    return ModuleHomeScaffold(
      title: 'Gaz • Détail et gros',
      enterpriseId: enterpriseId,
    );
  }
}
