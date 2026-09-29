import 'package:flutter/material.dart';

/// A complete visual theme for the game.
///
/// [blocks] is indexed by `ShapeKind.colorSlot`, so every piece family has
/// its own colour, as in the original 1010!. Palettes need at least nine
/// block colours; extra entries are available to future modes.
@immutable
class GamePalette {
  const GamePalette({
    required this.id,
    required this.name,
    required this.brightness,
    required this.background,
    required this.boardBackground,
    required this.emptyCell,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.blocks,
  });

  final String id;
  final String name;
  final Brightness brightness;

  /// Scaffold / page background.
  final Color background;

  /// Panel behind the grid.
  final Color boardBackground;
  final Color emptyCell;
  final Color textPrimary;
  final Color textSecondary;

  /// Buttons, highlights and the score.
  final Color accent;
  final List<Color> blocks;

  Color blockColor(int slot) => blocks[slot % blocks.length];

  ThemeData toThemeData() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: accent,
          brightness: brightness,
        ).copyWith(
          primary: accent,
          surface: background,
          onSurface: textPrimary,
          onSurfaceVariant: textSecondary,
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: boardBackground),
      dialogTheme: DialogThemeData(backgroundColor: boardBackground),
    );
  }
}
