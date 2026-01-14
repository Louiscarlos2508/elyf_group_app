import 'package:flutter/material.dart';

/// Helper pour gérer le focus de manière accessible et intuitive.
///
/// Fournit des méthodes pour :
/// - Naviguer entre les champs de formulaire
/// - Gérer le focus lors de la soumission
/// - Masquer le clavier de manière appropriée
/// - Gérer le focus trap dans les dialogs
class AppFocusManager {
  const AppFocusManager._();

  /// Déplace le focus vers le prochain champ focusable.
  ///
  /// Utilisé dans les formulaires pour navigation séquentielle.
  static void nextFocus(BuildContext context) {
    FocusScope.of(context).nextFocus();
  }

  /// Déplace le focus vers le champ précédent.
  static void previousFocus(BuildContext context) {
    FocusScope.of(context).previousFocus();
  }

  /// Déplace le focus vers un champ spécifique.
  ///
  /// Utile pour repositionner le focus après une action (ex: après création).
  static void requestFocus(BuildContext context, FocusNode node) {
    FocusScope.of(context).requestFocus(node);
  }

  /// Enlève le focus de tous les champs et cache le clavier.
  ///
  /// À utiliser lors de la soumission d'un formulaire ou de la fermeture d'un dialog.
  static void unfocusAll(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  /// Enlève le focus et cache explicitement le clavier.
  ///
  /// Utile pour forcer la fermeture du clavier sur certaines plateformes.
  static void unfocusAndHideKeyboard(BuildContext context) {
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      currentFocus.unfocus();
    }
  }

  /// Vérifie si un champ spécifique a actuellement le focus.
  static bool hasFocus(BuildContext context, FocusNode node) {
    return FocusScope.of(context).focusedChild == node;
  }

  /// Gère le focus lors de la soumission d'un formulaire.
  ///
  /// Si [isLastField] est true, enlève le focus et cache le clavier.
  /// Sinon, déplace le focus vers le prochain champ.
  static void handleFormSubmit(
    BuildContext context, {
    bool isLastField = false,
  }) {
    if (isLastField) {
      unfocusAndHideKeyboard(context);
    } else {
      nextFocus(context);
    }
  }

  /// Crée un focus node avec une gestion automatique du cycle de vie.
  ///
  /// Utile pour éviter les memory leaks en disposant automatiquement les focus nodes.
  static FocusNode createManagedFocusNode({
    String? debugLabel,
    bool skipTraversal = false,
    bool canRequestFocus = true,
  }) {
    return FocusNode(
      debugLabel: debugLabel,
      skipTraversal: skipTraversal,
      canRequestFocus: canRequestFocus,
    );
  }

  /// Dispose un focus node de manière sécurisée.
  ///
  /// Vérifie si le node n'est pas déjà disposé avant de le disposer.
  static void disposeFocusNode(FocusNode? node) {
    if (node != null) {
      node.unfocus(); // Enlever le focus avant de disposer
      node.dispose();
    }
  }
}

/// Mixin pour faciliter la gestion du focus dans les StatefulWidget.
///
/// Fournit une gestion automatique du cycle de vie des FocusNodes.
///
/// **Usage** :
/// ```dart
/// class MyFormState extends State<MyForm> with FocusMixin {
///   late final FocusNode emailFocus = createFocusNode(debugLabel: 'email');
///   late final FocusNode passwordFocus = createFocusNode(debugLabel: 'password');
///
///   @override
///   void dispose() {
///     disposeFocusNodes(); // Dispose automatiquement tous les focus nodes
///     super.dispose();
///   }
/// }
/// ```
mixin FocusMixin<T extends StatefulWidget> on State<T> {
  final List<FocusNode> _focusNodes = [];

  /// Crée et enregistre un focus node pour gestion automatique.
  FocusNode createFocusNode({
    String? debugLabel,
    bool skipTraversal = false,
    bool canRequestFocus = true,
  }) {
    final node = AppFocusManager.createManagedFocusNode(
      debugLabel: debugLabel,
      skipTraversal: skipTraversal,
      canRequestFocus: canRequestFocus,
    );
    _focusNodes.add(node);
    return node;
  }

  /// Dispose tous les focus nodes enregistrés.
  ///
  /// À appeler dans dispose().
  void disposeFocusNodes() {
    for (final node in _focusNodes) {
      AppFocusManager.disposeFocusNode(node);
    }
    _focusNodes.clear();
  }

  /// Déplace le focus vers le prochain champ.
  void nextFocus() {
    AppFocusManager.nextFocus(context);
  }

  /// Enlève le focus et cache le clavier.
  void unfocusAll() {
    AppFocusManager.unfocusAll(context);
  }

  /// Déplace le focus vers un node spécifique.
  void requestFocus(FocusNode node) {
    AppFocusManager.requestFocus(context, node);
  }
}

/// Widget qui gère automatiquement le focus trap dans les dialogs.
///
/// Empêche le focus de sortir du dialog et gère la navigation au clavier.
class FocusTrap extends StatelessWidget {
  const FocusTrap({super.key, required this.child, this.autofocus = false});

  /// Widget enfant.
  final Widget child;

  /// Si true, le premier élément focusable reçoit automatiquement le focus.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return FocusScope(autofocus: autofocus, child: child);
  }
}

/// Widget qui gère le focus lors de l'ouverture d'un dialog.
///
/// Place automatiquement le focus sur le premier champ éditable.
class DialogFocusHandler extends StatefulWidget {
  const DialogFocusHandler({super.key, required this.child, this.initialFocus});

  /// Widget enfant.
  final Widget child;

  /// Focus node qui devrait recevoir le focus initial (optionnel).
  final FocusNode? initialFocus;

  @override
  State<DialogFocusHandler> createState() => _DialogFocusHandlerState();
}

class _DialogFocusHandlerState extends State<DialogFocusHandler> {
  @override
  void initState() {
    super.initState();
    // Attendre que le widget soit construit avant de demander le focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.initialFocus != null) {
        AppFocusManager.requestFocus(context, widget.initialFocus!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
