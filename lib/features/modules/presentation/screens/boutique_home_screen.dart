import 'package:flutter/material.dart';

import '../widgets/module_home_scaffold.dart';

class BoutiqueHomeScreen extends StatelessWidget {
  const BoutiqueHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModuleHomeScaffold(
      title: 'Boutique • Vente physique',
      enterpriseId: 'boutique',
    );
  }
}
