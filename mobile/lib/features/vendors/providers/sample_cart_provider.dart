import 'package:flutter/material.dart';

class SampleCartItem {
  final int menuId;
  final String name;
  final double price;
  final int vendorId;

  SampleCartItem({required this.menuId, required this.name, required this.price, required this.vendorId});
}

class SampleCartProvider with ChangeNotifier {
  final List<SampleCartItem> _items = [];

  List<SampleCartItem> get items => _items;

  double get totalPrice => _items.fold(0, (sum, item) => sum + item.price);

  void addToCart(SampleCartItem item) {
    _items.add(item);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}