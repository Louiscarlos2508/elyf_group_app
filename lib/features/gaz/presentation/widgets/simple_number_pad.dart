import 'package:flutter/material.dart';

/// Un pavé numérique simple avec de gros boutons pour faciliter la saisie
/// de montants ou de quantités pour les utilisateurs non-tech.
class SimpleNumberPad extends StatelessWidget {
  const SimpleNumberPad({
    super.key,
    required this.onValueSelected,
    this.initialValue = '',
    this.suffix = 'FCFA',
    this.title = 'Saisir le montant',
  });

  final ValueChanged<String> onValueSelected;
  final String initialValue;
  final String suffix;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: _NumberPadContent(
        initialValue: initialValue,
        onValueSelected: onValueSelected,
        suffix: suffix,
        title: title,
      ),
    );
  }
}

class _NumberPadContent extends StatefulWidget {
  const _NumberPadContent({
    required this.initialValue,
    required this.onValueSelected,
    required this.suffix,
    required this.title,
  });

  final String initialValue;
  final ValueChanged<String> onValueSelected;
  final String suffix;
  final String title;

  @override
  State<_NumberPadContent> createState() => _NumberPadContentState();
}

class _NumberPadContentState extends State<_NumberPadContent> {
  late String _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
  }

  void _onKeyPress(String key) {
    setState(() {
      if (key == 'backspace') {
        if (_currentValue.isNotEmpty) {
          _currentValue = _currentValue.substring(0, _currentValue.length - 1);
        }
      } else if (key == 'clear') {
        _currentValue = '';
      } else {
        // Prevent leading zeros if length > 0
        if (_currentValue == '0') {
          _currentValue = key;
        } else {
          _currentValue += key;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _currentValue.isEmpty ? '0' : _currentValue,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.suffix,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            ...['1', '2', '3', '4', '5', '6', '7', '8', '9'].map((key) => _PadButton(
              label: key,
              onPressed: () => _onKeyPress(key),
            )),
            _PadButton(
              icon: Icons.backspace_outlined,
              onPressed: () => _onKeyPress('backspace'),
              isSpecial: true,
            ),
            _PadButton(
              label: '0',
              onPressed: () => _onKeyPress('0'),
            ),
            _PadButton(
              label: 'C',
              onPressed: () => _onKeyPress('clear'),
              isSpecial: true,
            ),
          ],
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () => widget.onValueSelected(_currentValue),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(60),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text('VALIDER / CONFIRMER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
      ],
    );
  }
}

class _PadButton extends StatelessWidget {
  const _PadButton({
    this.label,
    this.icon,
    required this.onPressed,
    this.isSpecial = false,
  });

  final String? label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool isSpecial;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Material(
      color: isSpecial 
        ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.5)
        : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: icon != null 
            ? Icon(icon, color: theme.colorScheme.onSurfaceVariant)
            : Text(
                label!,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
        ),
      ),
    );
  }
}
