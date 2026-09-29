# ten_ten_clone — a 2016-style 1010! puzzle

A minimalist, ad-free clone of the original **1010!** block puzzle, built with
Flutter, Riverpod, SharedPreferences and Firebase (Firestore + Auth).

Drag pieces onto the 10×10 board. Fill a row or column to clear it. The game
ends when none of the three pieces fit anywhere.

## Features

- **Headless game engine**: pure Dart, no Flutter imports, fully unit-tested.
- **The 19 standard pieces** (dot, lines 2–5 in both orientations, 2×2 and 3×3
  squares, small and large corners in all rotations), with weighted spawning.
- **Classic scoring**: 1 point per placed cell, plus a line bonus of
  `10·n(n+1)/2` (1 line = 10, 2 = 30, 3 = 60, …).
- **Touch handling**: drags start on the first move, the whole tray slot is
  grabbable, and the piece floats 64 px above your finger at full board scale.
  The drop target hit-tests at the piece's centre (not the finger), so
  bottom-row drops work naturally. Cells snap to the nearest grid position.
- **Hover ghost**: a preview of where the piece lands, and the lines it would
  clear light up in its colour.
- **Animations**: placed cells pop in; cleared cells shrink and fade in a ripple
  that spreads out from the placed piece.
- **4 themes**: Classic 2016, Neon, Pastel, Solarized Dark. Each has a colour
  for every piece family, and the choice is saved.
- **Save state**: every move is saved, so the game survives an app kill. The
  local best score is stored per mode.
- **Global leaderboard**: Firestore with anonymous auth. If Firebase isn't
  configured, the app falls back to an offline in-memory leaderboard
  automatically.

## Architecture

Feature-first clean architecture: each feature has `domain` (pure logic),
`data` (IO) and `presentation` (Riverpod + widgets).

```
lib/
├── main.dart                      # bootstrap: prefs, Firebase (graceful), ProviderScope
├── app.dart                       # MaterialApp + composition root (game over → submit score)
├── firebase_options.dart          # placeholder, replaced by `flutterfire configure`
├── core/
│   ├── constants/game_constants.dart
│   ├── firebase/firebase_bootstrap.dart
│   ├── routing/app_routes.dart
│   └── storage/shared_preferences_provider.dart
└── features/
    ├── board/
    │   ├── domain/                # ← headless engine, no Flutter
    │   │   ├── entities/          # Board, Shape, ShapeCatalog, GridPoint, GameState
    │   │   ├── services/          # ShapeGenerator, ScoringRules
    │   │   ├── game_mode.dart     # GameMode + registry (extension point)
    │   │   └── game_engine.dart   # place / preview / newGame
    │   ├── data/game_state_repository.dart
    │   └── presentation/          # GameController, BoardGrid (DragTarget), DraggableShape, …
    ├── themes/                    # GamePalette, 4 palettes, PaletteController, picker sheet
    └── leaderboard/               # LeaderboardRepository, Firestore + in-memory impls, page
```

### Adding a game mode

Everything mode-specific lives on `GameMode`
(`lib/features/board/domain/game_mode.dart`):

```dart
class MiniMode extends GameMode {
  const MiniMode();
  @override String get id => 'mini';
  @override String get displayName => 'Mini 8×8';
  @override int get boardSize => 8;
  @override ScoringRules get scoring => const ClassicScoring(pointsPerLine: 15);
}
```

Then add it to `GameModes.all` and override `gameModeProvider`, for example
from a mode picker. The engine, save slots (`game.<id>.save`), best scores and
leaderboard buckets (`leaderboards/<id>/scores`) are all keyed by the mode, so
nothing else needs to change. For custom rules, override `isGameOver`,
`createShapeGenerator` or `catalog`.

## Running

```bash
flutter pub get
flutter run            # Android / iOS / web
flutter test           # unit + widget tests
flutter analyze
```

## Firebase setup (optional)

The app works without Firebase. To enable the global leaderboard:

```bash
dart pub global activate flutterfire_cli
firebase login
flutterfire configure              # overwrites lib/firebase_options.dart
firebase deploy --only firestore   # deploys firestore.rules + indexes
```

Then enable **Anonymous** sign-in in the Firebase console (Authentication →
Sign-in method).

`firestore.rules` only allows a signed-in player to write their own
`leaderboards/{modeId}/scores/{uid}` document. The document shape is
validated, and the score can only go up.
