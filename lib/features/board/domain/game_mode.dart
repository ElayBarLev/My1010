import 'dart:math';

import '../../../core/constants/game_constants.dart';
import 'entities/board.dart';
import 'entities/shape.dart';
import 'entities/shape_catalog.dart';
import 'services/scoring_rules.dart';
import 'services/shape_generator.dart';

/// Everything that distinguishes one way of playing from another.
///
/// To add a mode (e.g. a smaller board, a timed mode or a puzzle mode),
/// subclass [GameMode], override what differs, and register it in
/// [GameModes.all]. The engine, persistence and UI are all driven by these
/// properties, so no other code needs to change.
abstract class GameMode {
  const GameMode();

  /// Stable id; used for save slots, best scores and leaderboard buckets.
  String get id;
  String get displayName;

  int get boardSize => GameConstants.boardSize;
  int get traySize => GameConstants.traySize;
  ShapeCatalog get catalog => ShapeCatalog.standard;
  ScoringRules get scoring => const ClassicScoring();

  ShapeGenerator createShapeGenerator(Random random) =>
      WeightedRandomShapeGenerator(catalog, random: random);

  /// The game ends when no remaining tray piece fits anywhere.
  bool isGameOver(Board board, List<Shape?> tray) {
    final remaining = tray.whereType<Shape>();
    if (remaining.isEmpty) return false;
    return remaining.every((shape) => !board.canPlaceAnywhere(shape));
  }
}

/// The original 10×10, three-piece endless mode.
class ClassicMode extends GameMode {
  const ClassicMode();

  @override
  String get id => 'classic';

  @override
  String get displayName => 'Classic';
}

abstract final class GameModes {
  static const classic = ClassicMode();

  static const List<GameMode> all = [classic];

  static GameMode byId(String id) =>
      all.firstWhere((m) => m.id == id, orElse: () => classic);
}
