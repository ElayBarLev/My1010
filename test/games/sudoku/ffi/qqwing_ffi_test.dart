import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my1010/games/sudoku/domain/sudoku_difficulty.dart';
import 'package:my1010/games/sudoku/ffi/qqwing_bindings.g.dart';
import 'package:my1010/games/sudoku/ffi/qqwing_library.dart';
import 'package:my1010/games/sudoku/ffi/qqwing_puzzle_source.dart';

import '../../../helpers/qqwing_library.dart';
import '../../../helpers/sudoku_solver.dart';

/// End-to-end: the CMake-built libqqwing_ffi, loaded through dart:ffi.
void main() {
  final libraryPath = buildQqwingLibrary();

  test('a missing library is reported as unavailable, not a crash', () {
    final source = QqwingPuzzleSource(libraryPath: '/nonexistent/lib.so');
    expect(source.isAvailable, isFalse);
  });

  group(
    'native library',
    skip: libraryPath == null ? 'CMake is not installed' : false,
    () {
      late QqwingPuzzleSource source;
      setUp(() => source = QqwingPuzzleSource(libraryPath: libraryPath));

      test('loads and reports its version', () {
        expect(source.isAvailable, isTrue);
        expect(source.version, '1.3.4');
      });

      for (final difficulty in SudokuDifficulty.values) {
        test('generates a valid, unique ${difficulty.label} puzzle', () async {
          final puzzle = await source.generate(difficulty, seed: 1234);

          expect(puzzle.difficulty, difficulty);
          expect(isValidSudokuSolution(puzzle.solution), isTrue);
          expect(puzzle.givenCount, inInclusiveRange(17, 40));
          expect(countSudokuSolutions(puzzle.givens), 1);
        });
      }

      test('difficulty levels match their QQWing ratings', () {
        for (final difficulty in SudokuDifficulty.values) {
          for (var seed = 1; seed <= 3; seed++) {
            late int guesses, advancedTechniques;
            QqwingPuzzleSource.generateBlocking(
              difficulty,
              seed,
              libraryPath: libraryPath,
              onStats: (stats) {
                guesses = stats.guess_count;
                advancedTechniques =
                    stats.naked_pair_count +
                    stats.hidden_pair_count +
                    stats.pointing_pair_triple_count +
                    stats.box_line_reduction_count;
              },
            );
            switch (difficulty) {
              case SudokuDifficulty.hard:
                expect(guesses, 0);
                expect(advancedTechniques, greaterThan(0));
              case SudokuDifficulty.veryHard:
                expect(guesses, inInclusiveRange(1, 2));
              case SudokuDifficulty.extreme:
                expect(guesses, greaterThanOrEqualTo(3));
            }
          }
        }
      });

      test('the same seed gives the same puzzle', () async {
        final a = await source.generate(SudokuDifficulty.hard, seed: 99);
        final b = await source.generate(SudokuDifficulty.hard, seed: 99);
        final c = await source.generate(SudokuDifficulty.hard, seed: 100);
        expect(a.givens, b.givens);
        expect(a.givens, isNot(c.givens));
      });

      test('concurrent generations from several isolates are safe', () async {
        final puzzles = await Future.wait([
          for (var seed = 0; seed < 6; seed++)
            source.generate(SudokuDifficulty.values[seed % 3], seed: seed),
        ]);
        for (final puzzle in puzzles) {
          expect(isValidSudokuSolution(puzzle.solution), isTrue);
        }
        // Seeding is per call despite QQWing's shared rand().
        final again = await source.generate(SudokuDifficulty.hard, seed: 0);
        expect(again.givens, puzzles[0].givens);
      });

      test('invalid arguments return an error and leave buffers alone', () {
        final bindings = openQqwing(path: libraryPath);
        using((arena) {
          final puzzle = arena<Int32>(QQWING_CELL_COUNT);
          final solution = arena<Int32>(QQWING_CELL_COUNT);
          puzzle[0] = 42;
          expect(
            bindings.qqwing_generate(7, 1, puzzle, solution, nullptr),
            QQWING_ERROR_INVALID_ARGUMENT,
          );
          expect(
            bindings.qqwing_generate(0, 1, nullptr, solution, nullptr),
            QQWING_ERROR_INVALID_ARGUMENT,
          );
          expect(puzzle[0], 42);
        });
      });
    },
  );
}
