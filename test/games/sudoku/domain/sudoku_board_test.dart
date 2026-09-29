import 'package:flutter_test/flutter_test.dart';
import 'package:my1010/games/sudoku/domain/sudoku_board.dart';
import 'package:my1010/games/sudoku/domain/sudoku_cell.dart';

import '../../../helpers/sudoku_fixtures.dart';
import '../../../helpers/sudoku_solver.dart';

int idx(int row, int col) => row * 9 + col;

void main() {
  test('the fixture grid is a valid Sudoku', () {
    expect(isValidSudokuSolution(solvedGrid), isTrue);
  });

  group('SudokuCell drafts are a bitmask', () {
    const cell = SudokuCell(row: 4, col: 7, correctValue: 3);

    test('bits 1-9, bit 0 unused', () {
      expect(SudokuCell.bit(1), 0x2);
      expect(SudokuCell.bit(9), 0x200);
      expect(SudokuCell.allDrafts, 0x3FE);
      expect(() => SudokuCell.bit(0), throwsRangeError);
      expect(() => SudokuCell.bit(10), throwsRangeError);
    });

    test('add, query and remove candidates', () {
      final noted = cell.withDraft(2).withDraft(9).withDraft(2);
      expect(noted.draftMask, SudokuCell.bit(2) | SudokuCell.bit(9));
      expect(noted.hasDraft(2), isTrue);
      expect(noted.hasDraft(3), isFalse);
      expect(noted.drafts, [2, 9]);
      expect(noted.withoutDraft(2).drafts, [9]);
      expect(noted.withoutDraft(5), noted);
    });

    test('position helpers', () {
      expect(cell.index, 43);
      expect(cell.block, 5);
    });
  });

  test('every cell has 20 distinct peers, symmetrically', () {
    for (var i = 0; i < 81; i++) {
      final peers = SudokuBoard.peers[i];
      expect(peers.toSet(), hasLength(20), reason: 'cell $i');
      expect(peers, isNot(contains(i)));
      for (final p in peers) {
        expect(SudokuBoard.peers[p], contains(i));
      }
    }
    expect(
      SudokuBoard.peers[idx(0, 0)],
      containsAll([idx(0, 8), idx(8, 0), idx(2, 2)]),
    );
    expect(SudokuBoard.peers[idx(0, 0)], isNot(contains(idx(3, 3))));
  });

  test('a new board marks the givens', () {
    final board = SudokuBoard.fromPuzzle(twoEmptyRows);
    expect(board[idx(0, 0)].isGiven, isFalse);
    expect(board[idx(0, 0)].isEmpty, isTrue);
    expect(board[idx(2, 0)].isGiven, isTrue);
    expect(board[idx(2, 0)].enteredValue, solvedGrid[idx(2, 0)]);
    expect(board.cells.any((c) => c.isError), isFalse);
  });

  group('placing numbers', () {
    test('clears the cell drafts and the number from every peer', () {
      // Cells 0-17 are empty: note 5 and 7 everywhere.
      var board = SudokuBoard.fromPuzzle(twoEmptyRows);
      final empty = List.generate(18, (i) => i);
      board = board.toggleDraft(empty, 5).toggleDraft(empty, 7);

      board = board.placeNumber([idx(0, 4)], 5);

      expect(board[idx(0, 4)].enteredValue, 5);
      expect(board[idx(0, 4)].draftMask, 0);
      // Same row, and same block on the next row: 5 gone, 7 kept.
      for (final peer in [idx(0, 0), idx(0, 8), idx(1, 3), idx(1, 5)]) {
        expect(board[peer].drafts, [7], reason: 'peer $peer');
      }
      // Row 1 outside the block is not a peer.
      expect(board[idx(1, 0)].drafts, [5, 7]);
    });

    test('flags duplicates in a row, column or block immediately', () {
      final base = SudokuBoard.fromPuzzle(puzzleWithHoles([0, 1, 9, 10, 40]));
      final given = solvedGrid[idx(2, 0)]; // below (0,0), same column/block

      final conflicted = base.placeNumber([idx(0, 0)], given);
      expect(conflicted[idx(0, 0)].isError, isTrue);
      expect(conflicted[idx(2, 0)].isError, isFalse, reason: 'givens never');

      // Two entered duplicates in the same row are both flagged.
      final pair = base.placeNumber([idx(0, 0)], 1).placeNumber([idx(0, 1)], 1);
      expect(pair[idx(0, 0)].isError, isTrue);
      expect(pair[idx(0, 1)].isError, isTrue);

      // On an empty grid: block-only, row-only and column-only duplicates.
      final empty = SudokuBoard.fromPuzzle(
        puzzleWithHoles(List.generate(81, (i) => i)),
      );
      SudokuBoard twoNines(int a, int b) =>
          empty.placeNumber([a], 9).placeNumber([b], 9);
      for (final (a, b) in [
        (idx(0, 0), idx(1, 1)), // block
        (idx(4, 0), idx(4, 8)), // row
        (idx(0, 6), idx(8, 6)), // column
      ]) {
        final board = twoNines(a, b);
        expect(board[a].isError && board[b].isError, isTrue, reason: '$a $b');
      }
      final apart = twoNines(idx(0, 0), idx(4, 4));
      expect(apart.cells.any((c) => c.isError), isFalse);

      // Fixing one of them clears both flags.
      final fixed = pair.erase([idx(0, 1)]);
      expect(fixed[idx(0, 0)].isError, isFalse);
      expect(fixed[idx(0, 1)].isError, isFalse);
    });

    test('a correct but unfinished grid has no errors', () {
      final board = SudokuBoard.fromPuzzle(twoEmptyRows)
          .placeNumber([idx(0, 0)], solvedGrid[0]);
      expect(board.cells.any((c) => c.isError), isFalse);
    });

    test('fills a multi-selection, skipping givens', () {
      final board = SudokuBoard.fromPuzzle(twoEmptyRows);
      final next = board.placeNumber([idx(0, 0), idx(1, 5), idx(4, 4)], 3);
      expect(next[idx(0, 0)].enteredValue, 3);
      expect(next[idx(1, 5)].enteredValue, 3);
      expect(next[idx(4, 4)], board[idx(4, 4)]);
    });

    test('placing the same number again removes it', () {
      final once = SudokuBoard.fromPuzzle(twoEmptyRows).placeNumber([0, 1], 4);
      final twice = once.placeNumber([0, 1], 4);
      expect(twice[0].isEmpty && twice[1].isEmpty, isTrue);
      // Mixed selection: fills instead of clearing.
      final mixed = once.erase([1]).placeNumber([0, 1], 4);
      expect(mixed[0].enteredValue, 4);
      expect(mixed[1].enteredValue, 4);
    });

    test('ignores givens entirely', () {
      final board = SudokuBoard.fromPuzzle(twoEmptyRows);
      expect(identical(board.placeNumber([idx(5, 5)], 1), board), isTrue);
      expect(identical(board.erase([idx(5, 5)]), board), isTrue);
    });
  });

  group('drafts', () {
    test('toggle across a selection: add to all unless all have it', () {
      var board = SudokuBoard.fromPuzzle(twoEmptyRows).toggleDraft([0], 6);
      board = board.toggleDraft([0, 1], 6);
      expect(board[0].drafts, [6]);
      expect(board[1].drafts, [6]);
      board = board.toggleDraft([0, 1], 6);
      expect(board[0].draftMask | board[1].draftMask, 0);
    });

    test('only in empty editable cells', () {
      final board = SudokuBoard.fromPuzzle(twoEmptyRows).placeNumber([0], 2);
      final next = board.toggleDraft([0, idx(5, 5)], 8);
      expect(identical(next, board), isTrue);
    });
  });

  test('erase clears the value first, then the drafts', () {
    var board = SudokuBoard.fromPuzzle(twoEmptyRows).toggleDraft([0], 1);
    board = board.erase([0]);
    expect(board[0].draftMask, 0);
    board = board.placeNumber([0], 2).erase([0]);
    expect(board[0].isEmpty, isTrue);
  });

  test('solved once every cell holds its correct value', () {
    var board = SudokuBoard.fromPuzzle(twoEmptyRows);
    for (var i = 0; i < 17; i++) {
      board = board.placeNumber([i], solvedGrid[i]);
    }
    expect(board.isSolved, isFalse);
    board = board.placeNumber([17], solvedGrid[17]);
    expect(board.isSolved, isTrue);
    expect(board.countOf(solvedGrid[0]), 9);
  });

  test('fromCells recomputes conflicts', () {
    final cells = [...SudokuBoard.fromPuzzle(twoEmptyRows).cells];
    cells[0] = cells[0].copyWith(enteredValue: cells[1 + 9 * 2].enteredValue);
    final board = SudokuBoard.fromCells(cells);
    expect(board[0].isError, cells[0].enteredValue != solvedGrid[0]);
    expect(() => SudokuBoard.fromCells(cells.sublist(1)), throwsArgumentError);
  });
}
