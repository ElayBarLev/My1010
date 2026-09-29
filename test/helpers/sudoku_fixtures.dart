import 'dart:async';

import 'package:my1010/games/sudoku/domain/sudoku_difficulty.dart';
import 'package:my1010/games/sudoku/domain/sudoku_puzzle.dart';

/// A valid solved grid: row r is 1-9 shifted by 3r + r ~/ 3.
final List<int> solvedGrid = List.unmodifiable([
  for (var i = 0; i < 81; i++) (i ~/ 9 * 3 + i ~/ 27 + i % 9) % 9 + 1,
]);

/// [solvedGrid] with the cells in [holes] emptied.
SudokuPuzzle puzzleWithHoles(
  Iterable<int> holes, {
  SudokuDifficulty difficulty = SudokuDifficulty.hard,
}) {
  final empty = holes.toSet();
  return SudokuPuzzle(
    givens: [
      for (var i = 0; i < 81; i++) empty.contains(i) ? 0 : solvedGrid[i],
    ],
    solution: solvedGrid,
    difficulty: difficulty,
  );
}

/// Every cell of the first two rows empty, the rest given.
final SudokuPuzzle twoEmptyRows = puzzleWithHoles(List.generate(18, (i) => i));

/// Serves scripted puzzles. With [hold], each request waits until
/// [release] is called so tests can observe the generating state.
class FakePuzzleSource implements SudokuPuzzleSource {
  FakePuzzleSource(this.puzzle, {this.hold = false, this.error});

  final SudokuPuzzle puzzle;
  final bool hold;
  final Object? error;

  final List<SudokuDifficulty> requests = [];
  final List<Completer<void>> _pending = [];

  @override
  bool get isAvailable => true;

  @override
  Future<SudokuPuzzle> generate(
    SudokuDifficulty difficulty, {
    int? seed,
  }) async {
    requests.add(difficulty);
    if (hold) {
      final gate = Completer<void>();
      _pending.add(gate);
      await gate.future;
    }
    if (error != null) throw error!;
    return SudokuPuzzle(
      givens: puzzle.givens,
      solution: puzzle.solution,
      difficulty: difficulty,
    );
  }

  /// Lets the oldest held request complete.
  void release() => _pending.removeAt(0).complete();
}
