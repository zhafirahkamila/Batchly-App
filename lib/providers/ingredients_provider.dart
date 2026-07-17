import 'package:flutter/foundation.dart';

import '../models/ingredient.dart';
import '../services/ingredients_service.dart';

class IngredientsProvider extends ChangeNotifier {
  final IngredientsService _service;
  IngredientsProvider(this._service);

  List<Ingredient> _items = [];
  bool _loading = false;
  String? _error;

  List<Ingredient> get items => _items;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _service.list();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Ingredient> create({
    required String name,
    required double purchasePrice,
    required double purchaseQty,
    required String purchaseUnit,
    String? category,
  }) async {
    final created = await _service.create(
      name: name,
      purchasePrice: purchasePrice,
      purchaseQty: purchaseQty,
      purchaseUnit: purchaseUnit,
      category: category,
    );
    _items = [..._items, created];
    notifyListeners();
    return created;
  }

  Future<Ingredient> update(int id, {
    required String name,
    required double purchasePrice,
    required double purchaseQty,
    required String purchaseUnit,
    String? category,
  }) async {
    final updated = await _service.update(
      id,
      name: name,
      purchasePrice: purchasePrice,
      purchaseQty: purchaseQty,
      purchaseUnit: purchaseUnit,
      category: category,
    );
    _items = _items.map((i) => i.id == id ? updated : i).toList();
    notifyListeners();
    return updated;
  }

  Future<void> delete(int id) async {
    await _service.delete(id);
    _items = _items.where((i) => i.id != id).toList();
    notifyListeners();
  }

  Ingredient? byId(int id) {
    for (final i in _items) {
      if (i.id == id) return i;
    }
    return null;
  }
}
