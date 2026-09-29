import 'package:meta/meta.dart';

import 'sudoku_cell.dart';
import 'sudoku_puzzle.dart';

/// An immutable 81-cell grid plus the player's moves on it.
///
/// Every operation returns a new board with [SudokuCell.isError] already
/// recomputed, so conflicts show up the moment a number is entered.
@immutable
class SudokuBoard {
  SudokuBoard._(List<SudokuCell> cells) : cells = List.unmodifiable(cells);

  /// A fresh board: givens filled in, everything else empty.
  factory SudokuBoard.fromPuzzle(SudokuPuzzle puzzle) => SudokuBoard._([
    for (var i = 0; i < cellCount; i++)
      SudokuCell(
        row: i ~/ 9,
        col: i % 9,
        correctValue: puzzle.solution[i],
        enteredValue: puzzle.givens[i],
        isGiven: puzzle.givens[i] != 0,
      ),
  ]);

  /// A board from arbitrary cells (e.g. a restored game). Conflicts are
  /// recomputed.
  factory SudokuBoard.fromCells(List<SudokuCell> cells) {
    if (cells.length != cellCount) {
      throw ArgumentError('A Sudoku has $cellCount cells.');
    }
    return SudokuBoard._(withConflicts(cells));
  }

  static const int cellCount = SudokuPuzzle.cellCount;

  final List<SudokuCell> cells;

  SudokuCell operator [](int index) => cells[index];

  /// The 20 cells sharing a row, column or block with each cell.
  static final List<List<int>> peers = List.unmodifiable([
    for (var i = 0; i < cellCount; i++) List<int>.unmodifiable(_peersOf(i)),
  ]);

  static List<int> _peersOf(int index) {
    final row = index ~/ 9, col = index % 9;
    final blockRow = row ~/ 3 * 3, blockCol = col ~/ 3 * 3;
    final result = <int>{
      for (var c = 0; c < 9; c++) row * 9 + c,
      for (var r = 0; r < 9; r++) r * 9 + col,
      for (var r = blockRow; r < blockRow + 3; r++)
        for (var c = blockCol; c < blockCol + 3; c++) r * 9 + c,
    }..remove(index);
    return result.toList()..sort();
  }

  /// Flags every editable cell whose value repeats in its row, column or
  /// block. Givens are never flagged: the clues are correct by definition.
  static List<SudokuCell> withConflicts(List<SudokuCell> cells) => [
    for (var i = 0; i < cells.length; i++)
      _flag(cells[i], _hasConflict(cells, i)),
  ];

  static bool _hasConflict(List<SudokuCell> cells, int index) {
    final cell = cells[index];
    if (cell.isGiven || cell.isEmpty) return false;
    for (final peer in peers[index]) {
      if (cells[peer].enteredValue == cell.enteredValue) return true;
    }
    return false;
  }

  static SudokuCell _flag(SudokuCell cell, bool isError) =>
      cell.isError == isError ? cell : cell.copyWith(isError: isError);

  /// Writes [number] into every editable cell among [indices].
  ///
  /// Placing a number clears the cell's drafts and removes [number] from
  /// the drafts of all its peers. If every target already holds [number],
  /// the number is removed instead (tapping it again undoes it).
  SudokuBoard placeNumber(Iterable<int> indices, int number) {
    SudokuCell.bit(number); // validates the range
    final targets = _editable(indices);
    if (targets.isEmpty) return this;
    final next = [...cells];

    if (targets.every((i) => cells[i].enteredValue == number)) {
      for (final i in targets) {
        next[i] = next[i].copyWith(enteredValue: 0);
      }
      return SudokuBoard._(withConflicts(next));
    }

    for (final i in targets) {
      next[i] = next[i].copyWith(enteredValue: number, draftMask: 0);
      for (final peer in peers[i]) {
        if (next[peer].hasDraft(number)) {
          next[peer] = next[peer].withoutDraft(number);
        }
      }
    }
    return SudokuBoard._(withConflicts(next));
  }

  /// Toggles the [number] draft in every empty editable cell among
  /// [indices]: removed from all of them if they all have it, otherwise
  /// added to all of them.
  SudokuBoard toggleDraft(Iterable<int> indices, int number) {
    SudokuCell.bit(number); // validates the range
    final targets = [
      for (final i in _editable(indices))
        if (cells[i].isEmpty) i,
    ];
    if (targets.isEmpty) return this;
    final remove = targets.every((i) => cells[i].hasDraft(number));
    final next = [...cells];
    for (final i in targets) {
      next[i] = remove
          ? next[i].withoutDraft(number)
          : next[i].withDraft(number);
    }
    return SudokuBoard._(next);
  }

  /// Clears the value of each editable cell among [indices], or its drafts
  /// when it has no value.
  SudokuBoard erase(Iterable<int> indices) {
    final targets = _editable(indices);
    if (targets.isEmpty) return this;
    final next = [...cells];
    for (final i in targets) {
      next[i] = next[i].isEmpty
          ? next[i].copyWith(draftMask: 0)
          : next[i].copyWith(enteredValue: 0);
    }
    return SudokuBoard._(withConflicts(next));
  }

  List<int> _editable(Iterable<int> indices) => [
    for (final i in indices.toSet())
      if (cells[i].isEditable) i,
  ];

  /// Cells (givens included) currently showing [number].
  int countOf(int number) =>
      cells.where((cell) => cell.enteredValue == number).length;

  bool get isSolved => cells.every((cell) => cell.isCorrect);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SudokuBoard) return false;
    for (var i = 0; i < cellCount; i++) {
      if (cells[i] != other.cells[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(cells);
}
