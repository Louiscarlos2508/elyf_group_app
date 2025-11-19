import 'package:flutter/material.dart';

import '../widgets/module_home_scaffold.dart';

class GazHomeScreen extends StatelessWidget {
  const GazHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModuleHomeScaffold(
      title: 'Gaz • Détail et gros',
      enterpriseId: 'gaz',
    );
  }
}
