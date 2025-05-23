import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UIProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  late SharedPreferences storage;

  setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    storage.setString("themeMode", _themeMode.toString());
    notifyListeners();
  }

  init() async {
    storage = await SharedPreferences.getInstance();
    String? storedTheme = storage.getString("themeMode");
    if (storedTheme != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (element) => element.toString() == storedTheme,
        orElse: () => ThemeMode.system,
      );
    }
    notifyListeners();
  }
}
