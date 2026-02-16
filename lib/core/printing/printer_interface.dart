import 'dart:typed_data';

/// Interface abstraite pour tous les types d'imprimantes (Sunmi, Bluetooth, USB, etc.)
abstract class PrinterInterface {
  /// Initialise l'imprimante et retourne true si succès
  Future<bool> initialize();

  /// Vérifie si l'imprimante est disponible/connectée
  Future<bool> isAvailable();

  /// Imprime du texte brut
  Future<bool> printText(String text);

  /// Imprime un reçu complet (parse le contenu pour le formatage)
  Future<bool> printReceipt(String content);

  /// Imprime une image (logo, QR code, etc.)
  Future<bool> printImage(Uint8List bytes);

  /// Ouvre le tiroir-caisse connecté
  Future<bool> openDrawer();

  /// Imprime une ligne avec plusieurs colonnes (auto-alignement)
  Future<bool> printRow(List<String> columns, {List<int>? weights, List<int>? alignments});

  /// Retourne la largeur de ligne en caractères (pour le formatage)
  Future<int> getLineWidth();

  /// Imprime un code-barres
  Future<bool> printBarCode(String data, {int? width, int? height});

  /// Imprime un QR code
  Future<bool> printQrCode(String data, {int? size});

  /// Libère les ressources
  Future<void> disconnect();
}
