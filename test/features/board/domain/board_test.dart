import 'package:flutter_test/flutter_test.dart';
import 'package:ten_ten_clone/features/board/domain/entities/board.dart';
import 'package:ten_ten_clone/features/board/domain/entities/grid_point.dart';

import '../../../helpers/test_shapes.dart';

void main() {
  group('Board basics', () {
    test('empty board has 100 empty cells', () {
      final board = Board.empty();
      expect(board.size, 10);
      expect(board.cells, hasLength(100));
      expect(board.isEmpty, isTrue);
    });

    test('fromCells rejects wrong cell counts', () {
      expect(
        () => Board.fromCells(10, List.filled(99, null)),
        throwsArgumentError,
      );
    });

    test('cells view is immutable', () {
      expect(() => Board.empty().cells[0] = 1, throwsUnsupportedError);
    });
  });

  group('Placement validation & collision', () {
    final board = Board.empty();

    test('accepts a placement fully inside an empty board', () {
      expect(board.canPlace(square3, const GridPoint(0, 0)), isTrue);
      expect(board.canPlace(square3, const GridPoint(7, 7)), isTrue);
    });

    test('rejects placements crossing the right/bottom edge', () {
      expect(board.canPlace(square3, const GridPoint(8, 0)), isFalse);
      expect(board.canPlace(square3, const GridPoint(0, 8)), isFalse);
      expect(board.canPlace(line5h, const GridPoint(0, 6)), isFalse);
      expect(board.canPlace(line5v, const GridPoint(6, 0)), isFalse);
    });

    test('rejects negative origins', () {
      expect(board.canPlace(dot, const GridPoint(-1, 0)), isFalse);
      expect(board.canPlace(dot, const GridPoint(0, -1)), isFalse);
    });

    test('rejects overlap with any filled cell', () {
      final occupied = board.place(dot, const GridPoint(4, 4));
      expect(occupied.canPlace(square3, const GridPoint(2, 2)), isFalse);
      expect(occupied.canPlace(square3, const GridPoint(4, 4)), isFalse);
      expect(occupied.canPlace(square3, const GridPoint(5, 5)), isTrue);
    });

    test('only the filled cells of a shape collide', () {
      // The big corner's empty top-left 2×2 area may sit over filled cells.
      final occupied = board.place(square2, const GridPoint(0, 0));
      expect(occupied.canPlace(cornerLargeSe, GridPoint.zero), isTrue);
      final blocked = occupied.place(dot, const GridPoint(2, 0));
      expect(blocked.canPlace(cornerLargeSe, GridPoint.zero), isFalse);
    });

    test('place stamps the colour slot and leaves the original intact', () {
      final next = board.place(square2, const GridPoint(1, 1));
      expect(next.cellAt(const GridPoint(1, 1)), square2.colorSlot);
      expect(next.cellAt(const GridPoint(2, 2)), square2.colorSlot);
      expect(next.filledCount, 4);
      expect(board.isEmpty, isTrue);
    });

    test('place throws on an invalid placement', () {
      final next = board.place(dot, const GridPoint(0, 0));
      expect(() => next.place(dot, const GridPoint(0, 0)), throwsStateError);
      expect(
        () => board.place(square3, const GridPoint(9, 9)),
        throwsStateError,
      );
    });
  });

  group('Line detection & clearing', () {
    test('detects a full row', () {
      final board = boardWithRowGaps(3, {});
      final lines = board.findFullLines();
      expect(lines.rows, [3]);
      expect(lines.cols, isEmpty);
    });

    test('an almost full row is not cleared', () {
      final lines = boardWithRowGaps(3, {9}).findFullLines();
      expect(lines.isEmpty, isTrue);
    });

    test('detects a full column', () {
      var board = Board.empty();
      board = board.place(line5v, const GridPoint(0, 6));
      board = board.place(line5v, const GridPoint(5, 6));
      final lines = board.findFullLines();
      expect(lines.cols, [6]);
      expect(lines.rows, isEmpty);
    });

    test(
      'clears rows and columns simultaneously, counting shared cells once',
      () {
        var board = boardWithRowGaps(0, {});
        for (var r = 1; r < 10; r++) {
          board = board.place(dot, GridPoint(r, 0));
        }
        board = board.place(dot, const GridPoint(5, 5)); // survives

        final lines = board.findFullLines();
        expect(lines.rows, [0]);
        expect(lines.cols, [0]);
        expect(lines.count, 2);
        expect(lines.cellIndices(10), hasLength(19));

        final cleared = board.clearLines(lines);
        expect(cleared.filledCount, 1);
        expect(cleared.isFilled(const GridPoint(5, 5)), isTrue);
      },
    );

    test('clearLines with no lines returns the same board', () {
      final board = Board.empty().place(dot, GridPoint.zero);
      expect(identical(board.clearLines(LineClear.none), board), isTrue);
    });
  });

  group('canPlaceAnywhere', () {
    test('true on an empty board for every standard shape', () {
      for (final shape in [dot, square3, line5h, line5v, cornerLargeSe]) {
        expect(Board.empty().canPlaceAnywhere(shape), isTrue, reason: shape.id);
      }
    });

    test('false when no 3×3 hole exists, while a dot still fits', () {
      final board = boardFromAscii([
        '#.#.#.#.#.',
        '.#.#.#.#.#',
        '#.#.#.#.#.',
        '.#.#.#.#.#',
        '#.#.#.#.#.',
        '.#.#.#.#.#',
        '#.#.#.#.#.',
        '.#.#.#.#.#',
        '#.#.#.#.#.',
        '.#.#.#.#.#',
      ]);
      expect(board.canPlaceAnywhere(square3), isFalse);
      expect(board.canPlaceAnywhere(square2), isFalse);
      expect(board.canPlaceAnywhere(dot), isTrue);
    });
  });

  test('JSON round-trip preserves every cell', () {
    final board = Board.empty()
        .place(square2, const GridPoint(3, 3))
        .place(line5h, const GridPoint(9, 0));
    final restored = Board.fromJson(10, board.toJson());
    expect(restored, board);
  });
}
