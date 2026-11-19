import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _settingsBoxName = 'settings_box';
  static const String _darkModeKey = 'is_dark_mode';

  ThemeProvider() : _isDarkMode = _readSavedTheme();

  bool _isDarkMode;

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  static bool _readSavedTheme() {
    final settingsBox = Hive.box(_settingsBoxName);
    return settingsBox.get(_darkModeKey, defaultValue: false) == true;
  }

  Future<void> setDarkMode(bool enabled) async {
    if (enabled == _isDarkMode) return;

    await Hive.box(_settingsBoxName).put(_darkModeKey, enabled);
    _isDarkMode = enabled;
    notifyListeners();
  }
}
