import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


/// Provider pour récupérer le stock d'un point de vente spécifique
final pointOfSaleStockProvider = FutureProvider.family<Map<String, int>, String>((ref, pointOfSaleId) async {
  final firestore = FirebaseFirestore.instance;
  
  // Récupérer le document du point de vente
  // Note: La structure exacte dépend de votre modèle de données Firestore
  // Hypothèse: points_of_sale/{id}/stock/{itemId} ou champ 'stock' dans le document
  
  try {
    // Approche 1: Collection 'stock' sous le point de vente
    final stockSnapshot = await firestore
        .collection('points_of_sale')
        .doc(pointOfSaleId)
        .collection('stock')
        .get();

    if (stockSnapshot.docs.isNotEmpty) {
      final stock = <String, int>{};
      for (final doc in stockSnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('quantity')) {
          stock[doc.id] = (data['quantity'] as num).toInt();
        }
      }
      return stock;
    } 
    
    // Approche 2: Champ 'currentStock' map dans le document principal
    final posDoc = await firestore.collection('points_of_sale').doc(pointOfSaleId).get();
    if (posDoc.exists) {
      final data = posDoc.data();
      if (data != null && data.containsKey('currentStock')) {
        final currentStock = data['currentStock'] as Map<String, dynamic>;
        return currentStock.map((key, value) => MapEntry(key, (value as num).toInt()));
      }
    }

    return {};
  } catch (e) {
    // En cas d'erreur, retourner une map vide plutôt que de faire planter l'UI
    return {};
  }
});
