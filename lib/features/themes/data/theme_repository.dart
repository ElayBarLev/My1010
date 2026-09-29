import 'package:shared_preferences/shared_preferences.dart';

/// Persists the selected palette id.
class ThemeRepository {
  ThemeRepository(this._prefs);

  static const _key = 'theme.paletteId';

  final SharedPreferences _prefs;

  String? loadPaletteId() => _prefs.getString(_key);

  Future<void> savePaletteId(String id) => _prefs.setString(_key, id);
}
