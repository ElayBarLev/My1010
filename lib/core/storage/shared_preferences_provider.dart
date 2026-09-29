import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app-wide [SharedPreferences] instance.
///
/// It is loaded once in `main()` and injected with `overrideWithValue`, which
/// lets every repository read synchronously (no loading states for settings
/// or the saved game) and lets tests inject mock preferences.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main() or in tests.',
  ),
);
