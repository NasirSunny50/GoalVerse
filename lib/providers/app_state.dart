import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global app preferences: theme, favourite teams, onboarding flag.
/// Persisted with shared_preferences for offline-first behaviour.
class AppState extends ChangeNotifier {
  AppState() {
    _load();
  }

  static const _kTheme = 'theme_mode';
  static const _kFavorites = 'favorite_teams';
  static const _kOnboarded = 'onboarded';

  SharedPreferences? _prefs;
  bool _ready = false;
  bool get ready => _ready;

  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  final Set<String> _favorites = {};
  Set<String> get favorites => _favorites;

  bool _onboarded = false;
  bool get onboarded => _onboarded;

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    final t = _prefs!.getString(_kTheme);
    _themeMode = t == 'light'
        ? ThemeMode.light
        : t == 'system'
            ? ThemeMode.system
            : ThemeMode.dark;
    _favorites
      ..clear()
      ..addAll(_prefs!.getStringList(_kFavorites) ?? const []);
    _onboarded = _prefs!.getBool(_kOnboarded) ?? false;
    _ready = true;
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    _prefs?.setString(_kTheme, isDark ? 'dark' : 'light');
    notifyListeners();
  }

  bool isFavorite(String teamId) => _favorites.contains(teamId);

  void toggleFavorite(String teamId) {
    if (!_favorites.remove(teamId)) _favorites.add(teamId);
    _prefs?.setStringList(_kFavorites, _favorites.toList());
    notifyListeners();
  }

  void completeOnboarding(Iterable<String> teamIds) {
    _favorites
      ..clear()
      ..addAll(teamIds);
    _onboarded = true;
    _prefs?.setStringList(_kFavorites, _favorites.toList());
    _prefs?.setBool(_kOnboarded, true);
    notifyListeners();
  }

  void resetOnboarding() {
    _onboarded = false;
    _prefs?.setBool(_kOnboarded, false);
    notifyListeners();
  }
}
