import 'package:flutter/widgets.dart';

/// A self-contained game the home menu can launch.
///
/// Each game lives in its own module under `lib/games/<name>/` and is
/// registered in `lib/games/game_registry.dart`. The home screen, routing and
/// leaderboard are all driven by these properties, so adding a game never
/// touches shared code.
abstract class GameInterface {
  const GameInterface();

  /// Stable id: used in routes (`/games/<id>`) and, when
  /// [supportsLeaderboard] is `true`, as the leaderboard bucket
  /// (`leaderboards/<id>/scores`).
  String get id;

  String get displayName;

  IconData get menuIcon;

  /// The full-screen page for this game. It owns its own state (via
  /// providers) and is shown under the `/games/<id>` route.
  Widget buildGameScreen();

  /// Whether finished games are submitted to the global leaderboard.
  bool get supportsLeaderboard;

  /// `false` when the game can't run on the current platform (e.g. a native
  /// engine that isn't bundled). The home menu shows it disabled.
  bool get isAvailable => true;
}
