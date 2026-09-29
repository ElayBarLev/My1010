import '../domain/sudoku_difficulty.dart';
import '../domain/sudoku_puzzle.dart';

/// Used where dart:ffi doesn't exist (web): Sudoku is shown as unavailable.
class _UnavailablePuzzleSource implements SudokuPuzzleSource {
  const _UnavailablePuzzleSource();

  @override
  bool get isAvailable => false;

  @override
  Future<SudokuPuzzle> generate(SudokuDifficulty difficulty, {int? seed}) =>
      Future.error(
        const SudokuGenerationException(
          'The native Sudoku generator is not available on this platform.',
        ),
      );
}

SudokuPuzzleSource createPuzzleSource() => const _UnavailablePuzzleSource();
