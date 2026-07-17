import 'package:flutter/foundation.dart';

import '../models/dashboard_item.dart';
import '../services/dashboard_service.dart';

enum DashboardSort { marginAsc, marginDesc, nameAsc, newest }

class DashboardProvider extends ChangeNotifier {
  final DashboardService _service;
  DashboardProvider(this._service);

  List<DashboardItem> _items = [];
  bool _loading = false;
  String? _error;
  DashboardSort _sort = DashboardSort.marginAsc;

  List<DashboardItem> get items => _sortedItems();
  bool get loading => _loading;
  String? get error => _error;
  DashboardSort get sort => _sort;

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _service.summary();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setSort(DashboardSort s) {
    _sort = s;
    notifyListeners();
  }

  List<DashboardItem> _sortedItems() {
    final list = [..._items];
    switch (_sort) {
      case DashboardSort.marginAsc:
        // Backend already sorts this way; we resort defensively.
        list.sort((a, b) => _cmpMargin(a.marginPercent, b.marginPercent));
        break;
      case DashboardSort.marginDesc:
        list.sort((a, b) => _cmpMargin(b.marginPercent, a.marginPercent));
        break;
      case DashboardSort.nameAsc:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case DashboardSort.newest:
        list.sort((a, b) {
          final ta = a.calculatedAt?.millisecondsSinceEpoch ?? 0;
          final tb = b.calculatedAt?.millisecondsSinceEpoch ?? 0;
          return tb.compareTo(ta);
        });
        break;
    }
    return list;
  }

  int _cmpMargin(double? a, double? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1; // nulls go last
    if (b == null) return -1;
    return a.compareTo(b);
  }
}
