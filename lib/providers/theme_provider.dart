import 'package:flutter/material.dart';

import '../core/storage/prefs_store.dart';

class ThemeProvider extends ChangeNotifier {
  final PrefsStore _prefs;
  ThemeMode _mode = ThemeMode.system;

  ThemeProvider(this._prefs);

  ThemeMode get mode => _mode;

  Future<void> load() async {
    _mode = await _prefs.readThemeMode();
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    await _prefs.writeThemeMode(mode);
  }
}
