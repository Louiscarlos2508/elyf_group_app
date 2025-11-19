import 'package:flutter/material.dart';

import '../widgets/module_home_scaffold.dart';

class ImmobilierHomeScreen extends StatelessWidget {
  const ImmobilierHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModuleHomeScaffold(
      title: 'Immobilier • Maisons',
      enterpriseId: 'immobilier',
    );
  }
}
