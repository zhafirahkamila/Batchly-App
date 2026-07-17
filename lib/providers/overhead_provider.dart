import 'package:flutter/foundation.dart';

import '../models/overhead.dart';
import '../services/overhead_service.dart';

class OverheadProvider extends ChangeNotifier {
  final OverheadService _service;
  OverheadProvider(this._service);

  List<Overhead> _items = [];
  bool _loading = false;
  String? _error;

  List<Overhead> get items => _items;
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

  Future<Overhead> create({
    required String name,
    required double amount,
    required String period,
  }) async {
    final r = await _service.create(name: name, amount: amount, period: period);
    _items = [..._items, r];
    notifyListeners();
    return r;
  }

  Future<Overhead> update(int id, {
    required String name,
    required double amount,
    required String period,
  }) async {
    final r = await _service.update(id, name: name, amount: amount, period: period);
    _items = _items.map((o) => o.id == id ? r : o).toList();
    notifyListeners();
    return r;
  }

  Future<void> delete(int id) async {
    await _service.delete(id);
    _items = _items.where((o) => o.id != id).toList();
    notifyListeners();
  }

  Overhead? byId(int id) {
    for (final o in _items) {
      if (o.id == id) return o;
    }
    return null;
  }
}
