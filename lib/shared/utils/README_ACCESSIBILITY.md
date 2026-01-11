# Guide d'Accessibilité

Ce guide explique comment utiliser les outils d'accessibilité de l'application pour garantir une expérience utilisateur accessible à tous.

## 🎯 Objectifs

L'application respecte les standards **WCAG 2.1 niveau AA** (minimum) avec un objectif **niveau AAA** pour les éléments critiques.

## 📚 Composants Principaux

### 1. ContrastChecker

Vérifie le contraste des couleurs selon WCAG 2.1.

```dart
import 'package:elyf_groupe_app/shared/utils/accessibility_helpers.dart';

// Vérifier si le contraste est suffisant
final meetsContrast = ContrastChecker.meetsContrastRatio(
  foreground: Colors.black,
  background: Colors.white,
  level: ContrastLevel.aa, // ou ContrastLevel.aaa
);

// Calculer le ratio exact
final ratio = ContrastChecker.calculateContrastRatio(
  Colors.black,
  Colors.white,
); // ≈ 21.0 (contraste maximum)

// Ajuster une couleur si le contraste est insuffisant
final adjustedColor = ContrastChecker.adjustColorForContrast(
  foreground: Colors.grey.shade400,
  background: Colors.grey.shade500,
  level: ContrastLevel.aa,
);
```

### 2. AccessibleWidgets

Helpers pour ajouter des semantics aux widgets.

#### Bouton Accessible

```dart
AccessibleWidgets.accessibleButton(
  label: 'Connexion',
  hint: 'Appuyez pour vous connecter',
  onTap: () => _handleLogin(),
  enabled: !isLoading,
  child: ElevatedButton(
    onPressed: _handleLogin,
    child: const Text('Se connecter'),
  ),
);
```

#### Champ de Texte Accessible

```dart
AccessibleWidgets.accessibleTextField(
  label: 'Adresse email',
  hint: 'Entrez votre adresse email',
  value: emailController.text,
  error: emailError,
  required: true,
  obscured: false,
  child: TextFormField(
    controller: emailController,
    decoration: const InputDecoration(
      labelText: 'Email',
      hintText: 'example@email.com',
    ),
  ),
);
```

#### Image Accessible

```dart
// Image avec description
AccessibleWidgets.accessibleImage(
  image: Image.asset('assets/logo.png'),
  label: 'Logo de l\'application Elyf Group',
);

// Image décorative (ignorée par le lecteur d'écran)
AccessibleWidgets.accessibleImage(
  image: Image.asset('assets/decoration.png'),
  excludeSemantics: true,
);
```

#### En-tête Accessible

```dart
AccessibleWidgets.accessibleHeader(
  level: 1, // Niveau 1-6 (comme HTML h1-h6)
  child: const Text(
    'Titre Principal',
    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
  ),
);
```

#### Région Live (pour changements dynamiques)

```dart
AccessibleWidgets.accessibleLiveRegion(
  label: 'Chargement en cours...',
  polite: true, // true = polie (n'interrompt pas), false = assertive
  child: CircularProgressIndicator(),
);
```

### 3. Widgets Accessibles Réutilisables

Utilisez directement les widgets prêts à l'emploi :

```dart
import 'package:elyf_groupe_app/shared/presentation/widgets/accessible_widgets.dart';

// Bouton accessible
AccessibleButton(
  label: 'Sauvegarder',
  hint: 'Sauvegarde les modifications',
  onPressed: _save,
  child: const Icon(Icons.save),
);

// Champ de texte accessible
AccessibleTextField(
  label: 'Nom',
  hint: 'Entrez votre nom',
  required: true,
  child: TextFormField(...),
);

// Carte accessible
AccessibleCard(
  label: 'Produit: ${product.name}',
  hint: 'Appuyez pour voir les détails',
  onTap: () => _showDetails(product),
  selected: selectedProduct == product,
  child: ProductCard(...),
);
```

### 4. Focus Management

#### AppFocusManager

```dart
import 'package:elyf_groupe_app/shared/utils/focus_manager.dart';

// Déplacer vers le prochain champ
AppFocusManager.nextFocus(context);

// Enlever le focus et masquer le clavier
AppFocusManager.unfocusAll(context);

// Déplacer vers un champ spécifique
AppFocusManager.requestFocus(context, emailFocusNode);

// Gérer le focus lors de la soumission
AppFocusManager.handleFormSubmit(
  context,
  isLastField: true, // Si c'est le dernier champ, cache le clavier
);
```

#### FocusMixin (pour StatefulWidget)

Gestion automatique du cycle de vie des FocusNodes :

```dart
class LoginFormState extends State<LoginForm> with FocusMixin {
  late final FocusNode emailFocus = createFocusNode(debugLabel: 'email');
  late final FocusNode passwordFocus = createFocusNode(debugLabel: 'password');

  @override
  void dispose() {
    disposeFocusNodes(); // Dispose automatiquement tous les focus nodes
    super.dispose();
  }

  void _handleSubmit() {
    // Navigation automatique entre champs
    nextFocus();
  }
}
```

#### FocusTrap (pour Dialogs)

Empêche le focus de sortir du dialog :

```dart
showDialog(
  context: context,
  builder: (context) => FocusTrap(
    autofocus: true, // Focus automatique sur le premier élément
    child: AlertDialog(
      title: const Text('Confirmation'),
      content: const Text('Êtes-vous sûr ?'),
      actions: [...],
    ),
  ),
);
```

#### DialogFocusHandler

Place automatiquement le focus sur le premier champ éditable :

```dart
showDialog(
  context: context,
  builder: (context) => DialogFocusHandler(
    initialFocus: emailFocusNode,
    child: AlertDialog(
      content: TextField(focusNode: emailFocusNode),
    ),
  ),
);
```

### 5. Vérification du Thème

Extension pour vérifier l'accessibilité du thème :

```dart
final theme = Theme.of(context);
final issues = theme.checkAccessibility(level: ContrastLevel.aa);

if (issues.isNotEmpty) {
  print('Problèmes d\'accessibilité détectés:');
  for (final issue in issues) {
    print('- $issue');
  }
}

// Obtenir une couleur avec contraste suffisant
final accessibleColor = theme.getAccessibleColor(
  foreground: colorScheme.primary,
  background: colorScheme.surface,
  level: ContrastLevel.aa,
);
```

## ✅ Checklist d'Accessibilité

### Pour chaque écran/widget :

- [ ] Tous les boutons ont un `label` sémantique
- [ ] Tous les champs de formulaire ont un `label` et un `hint`
- [ ] Les champs requis sont marqués comme `required`
- [ ] Les messages d'erreur sont annoncés par le lecteur d'écran
- [ ] Les images ont une description ou sont marquées comme décoratives
- [ ] Les en-têtes utilisent les niveaux appropriés (1-6)
- [ ] Le contraste des couleurs respecte WCAG AA (minimum)
- [ ] Le focus est géré correctement (navigation séquentielle)
- [ ] Les dialogs capturent le focus (FocusTrap)
- [ ] Les changements dynamiques sont annoncés (live regions)

### Pour les formulaires :

- [ ] Navigation au clavier (Tab) fonctionne correctement
- [ ] Soumission avec Enter fonctionne
- [ ] Focus retourne au premier champ en cas d'erreur
- [ ] Clavier masqué après soumission

### Pour les listes et tableaux :

- [ ] Chaque élément est annoncé avec son contexte
- [ ] Les actions (tap, swipe) sont clairement décrites
- [ ] Les états (sélectionné, activé) sont annoncés

## 🧪 Tests d'Accessibilité

### Tests Unitaires

```dart
import 'package:elyf_groupe_app/shared/utils/accessibility_helpers.dart';

test('contrast checker calcule correctement', () {
  final ratio = ContrastChecker.calculateContrastRatio(
    Colors.black,
    Colors.white,
  );
  expect(ratio, greaterThan(20.0));
});
```

### Tests Widget

```dart
testWidgets('button a les semantics correctes', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: AccessibleButton(
        label: 'Test',
        onPressed: () {},
        child: const Text('Test'),
      ),
    ),
  );

  final semantics = tester.getSemantics(find.text('Test'));
  expect(semantics.label, 'Test');
  expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);
});
```

## 📖 Ressources

- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Flutter Accessibility](https://docs.flutter.dev/accessibility-and-localization/accessibility)
- [Material Design Accessibility](https://material.io/design/usability/accessibility.html)

## 🚀 Prochaines Étapes

1. **Audit complet** : Vérifier tous les écrans existants
2. **Tests réels** : Tester avec TalkBack (Android) et VoiceOver (iOS)
3. **Linter CI/CD** : Ajouter des vérifications automatiques
4. **Documentation** : Créer des exemples pour chaque module

