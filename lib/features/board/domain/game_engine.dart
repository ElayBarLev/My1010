import 'dart:math';

import 'package:meta/meta.dart';

import 'entities/board.dart';
import 'entities/game_state.dart';
import 'entities/grid_point.dart';
import 'entities/shape.dart';
import 'game_mode.dart';
import 'services/shape_generator.dart';

/// What the board would look like if a piece were dropped here; used for
/// the hover ghost while dragging.
@immutable
class PlacementPreview {
  const PlacementPreview({
    required this.slot,
    required this.origin,
    required this.colorSlot,
    required this.cells,
    required this.clearingCells,
  });

  final int slot;
  final GridPoint origin;
  final int colorSlot;

  /// Cells the piece would occupy.
  final Set<int> cells;

  /// Cells (existing or new) that would be removed by resulting line clears.
  final Set<int> clearingCells;
}

/// Pure, UI-free rules of the game. Every method takes a [GameState] and
/// returns a new one, so the engine is trivially unit-testable and could
/// drive a CLI, a bot or a server just as well as Flutter.
class GameEngine {
  GameEngine({required this.mode, ShapeGenerator? generator, Random? random})
    : _generator = generator ?? mode.createShapeGenerator(random ?? Random());

  final GameMode mode;
  final ShapeGenerator _generator;

  GameState newGame({int bestScore = 0}) => GameState(
    modeId: mode.id,
    board: Board.empty(mode.boardSize),
    tray: _dealTray(),
    bestScore: bestScore,
  );

  bool canPlace(GameState state, int slot, GridPoint origin) {
    final shape = state.shapeAt(slot);
    return !state.isGameOver &&
        shape != null &&
        state.board.canPlace(shape, origin);
  }

  /// Returns `null` when the placement is invalid.
  PlacementPreview? preview(GameState state, int slot, GridPoint origin) {
    if (!canPlace(state, slot, origin)) return null;
    final shape = state.shapeAt(slot)!;
    final placed = state.board.place(shape, origin);
    return PlacementPreview(
      slot: slot,
      origin: origin,
      colorSlot: shape.colorSlot,
      cells: state.board.footprint(shape, origin).toSet(),
      clearingCells: placed.findFullLines().cellIndices(placed.size),
    );
  }

  /// Applies a move: stamp the piece, clear full lines, score, refill the
  /// tray when empty and detect game over. Returns `null` (state unchanged)
  /// if the move is illegal.
  GameState? place(GameState state, int slot, GridPoint origin) {
    if (!canPlace(state, slot, origin)) return null;
    final shape = state.shapeAt(slot)!;

    final placedBoard = state.board.place(shape, origin);
    final lines = placedBoard.findFullLines();
    final clearedIndices = lines.cellIndices(placedBoard.size);
    final board = placedBoard.clearLines(lines);

    final points =
        mode.scoring.placementPoints(shape) +
        mode.scoring.clearBonus(lines.count);
    final score = state.score + points;

    var tray = [...state.tray]..[slot] = null;
    if (tray.every((s) => s == null)) tray = _dealTray();

    return GameState(
      modeId: state.modeId,
      board: board,
      tray: List.unmodifiable(tray),
      score: score,
      bestScore: max(score, state.bestScore),
      moveCount: state.moveCount + 1,
      isGameOver: mode.isGameOver(board, tray),
      lastMove: MoveEvent(
        sequence: state.moveCount + 1,
        placedCells: state.board.footprint(shape, origin).toSet(),
        clearedCells: {
          for (final i in clearedIndices) i: placedBoard.cells[i]!,
        },
        linesCleared: lines.count,
        pointsGained: points,
      ),
    );
  }

  List<Shape?> _dealTray() => List.unmodifiable([
    for (var i = 0; i < mode.traySize; i++) _generator.next(),
  ]);
}
