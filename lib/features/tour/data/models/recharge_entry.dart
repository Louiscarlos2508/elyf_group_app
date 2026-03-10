import 'tour.dart';

// Recharge fournisseur
class RechargeEntry {
  final Map<FormatBouteille, int> videsRendus;   // = total collectes
  final Map<FormatBouteille, int> pleinesRecues; // = même quantité (1 pour 1)
  final int coutAchat;                           // en FCFA
  final DateTime timestamp;
  final String? ajustementRaison;               // si quantités modifiées

  const RechargeEntry({
    required this.videsRendus,
    required this.pleinesRecues,
    required this.coutAchat,
    required this.timestamp,
    this.ajustementRaison,
  });
}
