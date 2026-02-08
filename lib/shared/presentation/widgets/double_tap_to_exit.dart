import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Un widget qui nécessite une double pression sur le bouton retour pour quitter.
///
/// Affiche un SnackBar lors de la première pression.
/// Quitte l'application lors de la seconde pression si elle survient dans le délai imparti.
class DoubleTapToExit extends StatefulWidget {
  const DoubleTapToExit({
    super.key,
    required this.child,
    this.snackBarMessage = 'Appuyez encore pour quitter',
    this.duration = const Duration(seconds: 2),
  });

  final Widget child;
  final String snackBarMessage;
  final Duration duration;

  @override
  State<DoubleTapToExit> createState() => _DoubleTapToExitState();
}

class _DoubleTapToExitState extends State<DoubleTapToExit> {
  DateTime? _lastPressedTime;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final now = DateTime.now();
        final bool isDoubleTap = _lastPressedTime != null &&
            now.difference(_lastPressedTime!) < widget.duration;

        if (isDoubleTap) {
          await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
          return;
        }

        _lastPressedTime = now;
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.snackBarMessage),
              duration: widget.duration,
              behavior: SnackBarBehavior.floating,
              width: 280, // Largeur fixe pour un look toast centré
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          );
        }
      },
      child: widget.child,
    );
  }
}
