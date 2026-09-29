import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../storage/shared_preferences_provider.dart';
import 'palettes.dart';
import 'theme_repository.dart';
import 'game_palette.dart';

final themeRepositoryProvider = Provider<ThemeRepository>(
  (ref) => ThemeRepository(ref.watch(sharedPreferencesProvider)),
);

/// The palette currently in use. Restored synchronously on start-up.
final paletteProvider = NotifierProvider<PaletteController, GamePalette>(
  PaletteController.new,
);

class PaletteController extends Notifier<GamePalette> {
  @override
  GamePalette build() =>
      GamePalettes.byId(ref.watch(themeRepositoryProvider).loadPaletteId());

  Future<void> select(GamePalette palette) async {
    state = palette;
    await ref.read(themeRepositoryProvider).savePaletteId(palette.id);
  }
}
