import 'package:meta/meta.dart';

import 'board.dart';
import 'shape.dart';
import 'shape_catalog.dart';

/// What happened on the most recent placement; drives UI animations.
///
/// [sequence] increases monotonically so widgets can key their animations
/// on it and replay them exactly once per move.
@immutable
class MoveEvent {
  const MoveEvent({
    required this.sequence,
    required this.placedCells,
    required this.clearedCells,
    required this.linesCleared,
    required this.pointsGained,
  });

  final int sequence;

  /// Flat indices of the cells the placed shape now occupies (before any
  /// clearing).
  final Set<int> placedCells;

  /// Cleared cell index → the colour slot it had, so the UI can animate the
  /// block away in its original colour.
  final Map<int, int> clearedCells;
  final int linesCleared;
  final int pointsGained;
}

/// A complete, immutable snapshot of one game.
@immutable
class GameState {
  const GameState({
    required this.modeId,
    required this.board,
    required this.tray,
    this.score = 0,
    this.bestScore = 0,
    this.moveCount = 0,
    this.isGameOver = false,
    this.lastMove,
  });

  static const int _schemaVersion = 1;

  final String modeId;
  final Board board;

  /// Tray slots; `null` means that slot's piece has already been used.
  final List<Shape?> tray;
  final int score;
  final int bestScore;
  final int moveCount;
  final bool isGameOver;

  /// Transient; not persisted.
  final MoveEvent? lastMove;

  Shape? shapeAt(int slot) =>
      slot >= 0 && slot < tray.length ? tray[slot] : null;

  GameState copyWith({int? bestScore}) => GameState(
    modeId: modeId,
    board: board,
    tray: tray,
    score: score,
    bestScore: bestScore ?? this.bestScore,
    moveCount: moveCount,
    isGameOver: isGameOver,
    lastMove: lastMove,
  );

  Map<String, Object?> toJson() => {
    'version': _schemaVersion,
    'modeId': modeId,
    'boardSize': board.size,
    'board': board.toJson(),
    'tray': [for (final s in tray) s?.id],
    'score': score,
    'moveCount': moveCount,
    'isGameOver': isGameOver,
  };

  /// Restores a snapshot. Throws [FormatException] on unknown versions or
  /// shape ids so callers can discard corrupt saves.
  factory GameState.fromJson(
    Map<String, Object?> json, {
    required ShapeCatalog catalog,
    int bestScore = 0,
  }) {
    if (json['version'] != _schemaVersion) {
      throw FormatException('Unsupported save version: ${json['version']}');
    }
    Shape? lookup(Object? id) {
      if (id == null) return null;
      return catalog.byId(id as String) ??
          (throw FormatException('Unknown shape id: $id'));
    }

    return GameState(
      modeId: json['modeId']! as String,
      board: Board.fromJson(
        json['boardSize']! as int,
        json['board']! as List<dynamic>,
      ),
      tray: [for (final id in json['tray']! as List<dynamic>) lookup(id)],
      score: json['score']! as int,
      moveCount: json['moveCount'] as int? ?? 0,
      isGameOver: json['isGameOver'] as bool? ?? false,
      bestScore: bestScore,
    );
  }
}
