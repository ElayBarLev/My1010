import 'package:flutter/material.dart';

import '../domain/game_palette.dart';

/// Built-in palettes. Block colour order follows `ShapeKind`:
/// dot, line2, line3, line4, line5, square2, square3, cornerSmall,
/// cornerLarge.
abstract final class GamePalettes {
  /// The flat, light look of the 2016 original: soft grey empty cells and a
  /// family-coded rainbow of blocks.
  static const classic = GamePalette(
    id: 'classic',
    name: 'Classic 2016',
    brightness: Brightness.light,
    background: Color(0xFFFFFFFF),
    boardBackground: Color(0xFFFFFFFF),
    emptyCell: Color(0xFFE6E6E6),
    textPrimary: Color(0xFF3D3D3D),
    textSecondary: Color(0xFF9A9A9A),
    accent: Color(0xFF5BBEE5),
    blocks: [
      Color(0xFF7B8ED5), // dot – periwinkle
      Color(0xFFFEC63D), // line2 – yellow
      Color(0xFFFC9A43), // line3 – orange
      Color(0xFFEB6C82), // line4 – pink
      Color(0xFFDC5A56), // line5 – red
      Color(0xFF98DC55), // square2 – lime
      Color(0xFF4DD5B0), // square3 – teal
      Color(0xFF5ACB86), // cornerSmall – green
      Color(0xFF5BBEE5), // cornerLarge – sky
    ],
  );

  /// Synthwave-inspired neon on near-black.
  static const neon = GamePalette(
    id: 'neon',
    name: 'Neon',
    brightness: Brightness.dark,
    background: Color(0xFF0B0B14),
    boardBackground: Color(0xFF12121F),
    emptyCell: Color(0xFF1E1E30),
    textPrimary: Color(0xFFF1F1FF),
    textSecondary: Color(0xFF8A8AA8),
    accent: Color(0xFF00F0FF),
    blocks: [
      Color(0xFFB026FF), // violet
      Color(0xFFFFE600), // electric yellow
      Color(0xFFFF6B00), // blaze orange
      Color(0xFFFF2E97), // hot pink
      Color(0xFFFF3864), // neon red
      Color(0xFF39FF14), // neon green
      Color(0xFF00FF9F), // spring green
      Color(0xFF2DE2E6), // cyan
      Color(0xFF3D8BFF), // electric blue
    ],
  );

  /// The popular "pastel rainbow" palette on warm paper.
  static const pastel = GamePalette(
    id: 'pastel',
    name: 'Pastel',
    brightness: Brightness.light,
    background: Color(0xFFFAF7F2),
    boardBackground: Color(0xFFFAF7F2),
    emptyCell: Color(0xFFEBE5DE),
    textPrimary: Color(0xFF5B5566),
    textSecondary: Color(0xFFA59EAF),
    accent: Color(0xFF9D8DF1),
    blocks: [
      Color(0xFFBDB2FF), // lavender
      Color(0xFFFFD6A5), // apricot
      Color(0xFFFFB5A7), // peach
      Color(0xFFFFADAD), // rose
      Color(0xFFFF9AA2), // salmon
      Color(0xFFCAFFBF), // mint
      Color(0xFF9BF6FF), // sky
      Color(0xFFB5EAD7), // seafoam
      Color(0xFFA0C4FF), // periwinkle
    ],
  );

  /// Ethan Schoonover's Solarized (dark variant): base03/base02 surfaces and
  /// the eight accent colours plus base1.
  static const solarizedDark = GamePalette(
    id: 'solarized_dark',
    name: 'Solarized Dark',
    brightness: Brightness.dark,
    background: Color(0xFF002B36), // base03
    boardBackground: Color(0xFF002B36), // base03
    emptyCell: Color(0xFF073642), // base02
    textPrimary: Color(0xFF93A1A1), // base1
    textSecondary: Color(0xFF586E75), // base01
    accent: Color(0xFF268BD2), // blue
    blocks: [
      Color(0xFF6C71C4), // violet
      Color(0xFFB58900), // yellow
      Color(0xFFCB4B16), // orange
      Color(0xFFD33682), // magenta
      Color(0xFFDC322F), // red
      Color(0xFF859900), // green
      Color(0xFF2AA198), // cyan
      Color(0xFF93A1A1), // base1
      Color(0xFF268BD2), // blue
    ],
  );

  static const List<GamePalette> all = [classic, neon, pastel, solarizedDark];

  static GamePalette byId(String? id) =>
      all.firstWhere((p) => p.id == id, orElse: () => classic);
}
