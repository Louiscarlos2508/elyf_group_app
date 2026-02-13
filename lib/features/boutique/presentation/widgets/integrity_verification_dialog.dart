import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../application/providers.dart';

class IntegrityVerificationDialog extends ConsumerStatefulWidget {
  const IntegrityVerificationDialog({super.key});

  @override
  ConsumerState<IntegrityVerificationDialog> createState() => _IntegrityVerificationDialogState();
}

class _IntegrityVerificationDialogState extends ConsumerState<IntegrityVerificationDialog> {
  bool _isVerifying = false;
  bool? _isSuccess;
  String? _errorMessage;
  int _totalChecked = 0;

  Future<void> _startVerification() async {
    setState(() {
      _isVerifying = true;
      _isSuccess = null;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(saleRepositoryProvider);
      // Assuming verifyChain returns true if everything is OK
      final result = await repository.verifyChain();
      
      // Get count for feedback
      final sales = await repository.fetchSales();
      
      setState(() {
        _isSuccess = result;
        _totalChecked = sales.length;
        _isVerifying = false;
      });
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _errorMessage = e.toString();
        _isVerifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.verified_user_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          const Text('Vérification du Registre'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Cette opération vérifie l\'intégrité mathématique de toutes vos ventes en recalculant le chaînage des signatures (hachage).',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            if (_isVerifying) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Analyse des transactions en cours...'),
            ] else if (_isSuccess == true) ...[
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Registre Intègre',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green),
              ),
              const SizedBox(height: 8),
              Text(
                'Les $_totalChecked transactions ont été vérifiées avec succès. Aucune altération n\'a été détectée.',
                textAlign: TextAlign.center,
              ),
            ] else if (_isSuccess == false) ...[
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Alerte d\'Intégrité',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Une incohérence a été détectée dans la chaîne de signatures des transactions.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ] else ...[
              const Icon(Icons.security, color: Colors.blueGrey, size: 64),
              const SizedBox(height: 16),
              const Text('Prêt pour vérification'),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isVerifying ? null : () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
        if (_isSuccess == null && !_isVerifying)
          FilledButton.icon(
            onPressed: _startVerification,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Lancer l\'Analyse'),
          ),
      ],
    );
  }
}
