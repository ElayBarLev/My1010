import 'package:meta/meta.dart';

import 'sudoku_difficulty.dart';

/// A generated puzzle: its givens and its unique solution, row-major.
@immutable
class SudokuPuzzle {
  SudokuPuzzle({
    required List<int> givens,
    required List<int> solution,
    required this.difficulty,
  }) : givens = List.unmodifiable(givens),
       solution = List.unmodifiable(solution) {
    if (givens.length != cellCount || solution.length != cellCount) {
      throw ArgumentError('A Sudoku has $cellCount cells.');
    }
    for (var i = 0; i < cellCount; i++) {
      final s = solution[i], g = givens[i];
      if (s < 1 || s > 9 || (g != 0 && g != s)) {
        throw ArgumentError('Cell $i: given $g does not match solution $s.');
      }
    }
  }

  static const int size = 9;
  static const int cellCount = size * size;

  /// 0 for an empty cell, otherwise 1-9.
  final List<int> givens;

  /// 1-9 for every cell.
  final List<int> solution;

  final SudokuDifficulty difficulty;

  int get givenCount => givens.where((v) => v != 0).length;
}

/// Produces puzzles. Implemented natively by QQWing over dart:ffi.
abstract interface class SudokuPuzzleSource {
  /// `false` when the native generator isn't available on this platform.
  bool get isAvailable;

  /// Generates a puzzle with a unique solution. The same [seed] gives the
  /// same puzzle on a given platform; `null` picks a random one.
  ///
  /// Throws [SudokuGenerationException] on failure.
  Future<SudokuPuzzle> generate(SudokuDifficulty difficulty, {int? seed});
}

class SudokuGenerationException implements Exception {
  const SudokuGenerationException(this.message);

  final String message;

  @override
  String toString() => 'SudokuGenerationException: $message';
}
