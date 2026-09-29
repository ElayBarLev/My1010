import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ten_ten_clone/features/board/domain/entities/board.dart';
import 'package:ten_ten_clone/features/board/domain/entities/game_state.dart';
import 'package:ten_ten_clone/features/board/domain/entities/grid_point.dart';
import 'package:ten_ten_clone/features/board/domain/entities/shape.dart';
import 'package:ten_ten_clone/features/board/domain/entities/shape_catalog.dart';
import 'package:ten_ten_clone/features/board/domain/game_engine.dart';
import 'package:ten_ten_clone/features/board/domain/game_mode.dart';
import 'package:ten_ten_clone/features/board/domain/services/shape_generator.dart';

import '../../../helpers/test_shapes.dart';

GameEngine engineWith(List<Shape> sequence) => GameEngine(
  mode: GameModes.classic,
  generator: SequenceShapeGenerator(sequence),
);

GameState stateWith(Board board, List<Shape?> tray, {int score = 0}) =>
    GameState(modeId: 'classic', board: board, tray: tray, score: score);

void main() {
  group('Shape catalog', () {
    test('contains the 19 standard 1010! pieces with unique ids', () {
      final shapes = ShapeCatalog.standard.shapes;
      expect(shapes, hasLength(19));
      expect(shapes.map((s) => s.id).toSet(), hasLength(19));
    });

    test('every shape is normalised to (0,0) and fits a 5×5 box', () {
      for (final s in ShapeCatalog.standard.shapes) {
        expect(s.cells.map((p) => p.row).reduce(min), 0, reason: s.id);
        expect(s.cells.map((p) => p.col).reduce(min), 0, reason: s.id);
        expect(s.width, inInclusiveRange(1, 5), reason: s.id);
        expect(s.height, inInclusiveRange(1, 5), reason: s.id);
      }
    });

    test('weighted generator is deterministic for a seeded Random', () {
      List<String> roll(int seed) {
        final g = WeightedRandomShapeGenerator(
          ShapeCatalog.standard,
          random: Random(seed),
        );
        return [for (var i = 0; i < 20; i++) g.next().id];
      }

      expect(roll(42), roll(42));
      expect(roll(42).toSet().length, greaterThan(3));
    });
  });

  group('GameEngine', () {
    test('newGame deals a full tray on an empty board', () {
      final state = engineWith([dot, square2, line5h]).newGame(bestScore: 77);
      expect(state.board.isEmpty, isTrue);
      expect(state.tray, [dot, square2, line5h]);
      expect(state.score, 0);
      expect(state.bestScore, 77);
      expect(state.isGameOver, isFalse);
    });

    test('valid placement scores one point per cell and empties the slot', () {
      final engine = engineWith([square2, dot, dot]);
      final next = engine.place(engine.newGame(), 0, const GridPoint(4, 4))!;
      expect(next.score, 4);
      expect(next.tray[0], isNull);
      expect(next.board.filledCount, 4);
      expect(next.lastMove!.pointsGained, 4);
      expect(next.lastMove!.linesCleared, 0);
      expect(next.moveCount, 1);
    });

    test('invalid placements return null and leave state untouched', () {
      final engine = engineWith([square3, dot, dot]);
      final state = engine.newGame();
      expect(engine.place(state, 0, const GridPoint(8, 8)), isNull);
      expect(engine.place(state, 5, GridPoint.zero), isNull);

      final used = engine.place(state, 1, GridPoint.zero)!;
      expect(
        engine.place(used, 1, const GridPoint(5, 5)),
        isNull,
        reason: 'slot 1 is already used',
      );
      expect(
        engine.place(used, 0, GridPoint.zero),
        isNull,
        reason: 'collides with the dot',
      );
    });

    test('completing a row clears it and awards the line bonus', () {
      final engine = engineWith([dot]);
      final state = stateWith(boardWithRowGaps(9, {4}), [dot, null, square2]);
      final next = engine.place(state, 0, const GridPoint(9, 4))!;

      expect(next.board.isEmpty, isTrue);
      expect(next.score, 1 + 10);
      expect(next.lastMove!.linesCleared, 1);
      expect(next.lastMove!.clearedCells, hasLength(10));
      expect(next.lastMove!.clearedCells[94], dot.colorSlot);
    });

    test('a row + column combo is scored as two lines', () {
      var board = boardWithRowGaps(0, {0});
      for (var r = 1; r < 10; r++) {
        board = board.place(dot, GridPoint(r, 0));
      }
      final engine = engineWith([dot]);
      final next = engine.place(
        stateWith(board, [dot, square2, null]),
        0,
        GridPoint.zero,
      )!;
      expect(next.lastMove!.linesCleared, 2);
      expect(next.score, 1 + 30);
      expect(next.board.isEmpty, isTrue);
    });

    test('tray refills only after all three pieces are used', () {
      final engine = engineWith([dot, dot, dot, square2, square2, square2]);
      var state = engine.newGame();
      state = engine.place(state, 0, const GridPoint(0, 0))!;
      state = engine.place(state, 1, const GridPoint(0, 2))!;
      expect(state.tray, [null, null, dot]);
      state = engine.place(state, 2, const GridPoint(0, 4))!;
      expect(state.tray, [square2, square2, square2]);
    });

    test('game over when no remaining piece fits', () {
      // Checkerboard: only isolated 1×1 holes, so the 2×2 square can never
      // fit, and filling one hole doesn't complete any line.
      final board = boardFromAscii([
        for (var r = 0; r < 10; r++) r.isEven ? '#.#.#.#.#.' : '.#.#.#.#.#',
      ]);
      final engine = engineWith([square2]);
      final state = stateWith(board, [dot, square2, null]);

      final next = engine.place(state, 0, const GridPoint(0, 1))!;
      expect(next.isGameOver, isTrue);
      expect(
        engine.place(next, 1, const GridPoint(0, 3)),
        isNull,
        reason: 'no moves are accepted after game over',
      );
    });

    test('best score tracks the highest score reached', () {
      final engine = engineWith([square3, dot, dot]);
      final next = engine.place(
        engine.newGame(bestScore: 5),
        0,
        GridPoint.zero,
      )!;
      expect(next.bestScore, 9);
    });

    test('preview reports footprint and cells that would clear', () {
      final engine = engineWith([dot]);
      final state = stateWith(boardWithRowGaps(2, {7}), [dot, null, null]);
      final preview = engine.preview(state, 0, const GridPoint(2, 7))!;
      expect(preview.cells, {27});
      expect(preview.clearingCells, {for (var c = 0; c < 10; c++) 20 + c});
      expect(engine.preview(state, 0, const GridPoint(2, 6)), isNull);
    });
  });

  test('GameState JSON round-trip', () {
    final engine = engineWith([square2, line5v, cornerLargeSe]);
    final state = engine.place(engine.newGame(), 1, const GridPoint(2, 3))!;
    final restored = GameState.fromJson(
      state.toJson(),
      catalog: ShapeCatalog.standard,
      bestScore: 12,
    );
    expect(restored.board, state.board);
    expect(restored.tray, state.tray);
    expect(restored.score, state.score);
    expect(restored.moveCount, state.moveCount);
    expect(restored.bestScore, 12);
  });

  test('GameState.fromJson rejects unknown shapes', () {
    final json = engineWith([dot]).newGame().toJson()
      ..['tray'] = ['nope', null, null];
    expect(
      () => GameState.fromJson(json, catalog: ShapeCatalog.standard),
      throwsFormatException,
    );
  });
}
