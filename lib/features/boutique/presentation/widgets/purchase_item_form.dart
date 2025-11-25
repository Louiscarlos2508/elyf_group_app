import 'package:flutter/material.dart';

import '../../domain/entities/product.dart';

class PurchaseItemForm {
  PurchaseItemForm({
    required this.product,
    required this.quantityController,
    required this.priceController,
  });

  final Product product;
  final TextEditingController quantityController;
  final TextEditingController priceController;
}

