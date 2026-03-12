// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:elyf_groupe_app/firebase_options.dart';

// Run this with: flutter test test/scripts/neutralize_negative_stock_test.dart
void main() {
  testWidgets('Neutralize negative stock in Firestore', (WidgetTester tester) async {
    // We need to initialize Firebase for this script to work.
    // Ensure you have a valid internet connection and google-services.json
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      print('Firebase initialized.');

      final firestore = FirebaseFirestore.instance;
      final stocksRef = firestore.collection('cylinder_stocks');
      
      final querySnapshot = await stocksRef.where('quantity', isLessThan: 0).get();
      
      if (querySnapshot.docs.isEmpty) {
        print('No negative stocks found.');
        return;
      }
      
      print('Found \${querySnapshot.docs.length} stocks with negative quantity. Correcting...');
      
      final batch = firestore.batch();
      int count = 0;
      
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'quantity': 0});
        count++;
        
        if (count % 500 == 0) {
          await batch.commit();
          print('Committed batch of 500...');
        }
      }
      
      if (count % 500 != 0) {
        await batch.commit();
        print('Committed final batch of \${count % 500}...');
      }
      
      print('Successfully neutralized negative stocks.');
    } catch (e) {
      print('Error neutralizing negative stocks: \$e');
    }
  });
}
