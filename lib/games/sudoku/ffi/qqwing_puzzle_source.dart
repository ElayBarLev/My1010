import 'dart:ffi';
import 'dart:isolate';
import 'dart:math';

import 'package:ffi/ffi.dart';

import '../domain/sudoku_difficulty.dart';
import '../domain/sudoku_puzzle.dart';
import 'qqwing_bindings.g.dart';
import 'qqwing_library.dart';

/// Generates puzzles with the native QQWing engine.
///
/// Generation takes from a few milliseconds up to about a second (Extreme
/// may rate dozens of candidates), so it runs on a short-lived background
/// isolate and never blocks the UI thread.
class QqwingPuzzleSource implements SudokuPuzzleSource {
  QqwingPuzzleSource({this.libraryPath, Random? random})
    : _random = random ?? Random.secure();

  /// Overrides where the library is loaded from (see [openQqwing]).
  final String? libraryPath;
  final Random _random;

  late final bool _isAvailable = () {
    try {
      openQqwing(path: libraryPath);
      return true;
    } on Object {
      return false;
    }
  }();

  @override
  bool get isAvailable => _isAvailable;

  /// The bundled QQWing version, e.g. `1.3.4`.
  String get version =>
      openQqwing(path: libraryPath)
          .qqwing_version()
          .cast<Utf8>()
          .toDartString();

  @override
  Future<SudokuPuzzle> generate(
    SudokuDifficulty difficulty, {
    int? seed,
  }) async {
    final path = libraryPath;
    final actualSeed = seed ?? _random.nextInt(1 << 32);
    // Only primitives cross the isolate boundary; the library is opened
    // (and all native memory allocated and freed) inside the isolate.
    final (givens, solution) = await Isolate.run(
      () => generateBlocking(difficulty, actualSeed, libraryPath: path),
      debugName: 'qqwing-generate',
    );
    return SudokuPuzzle(
      givens: givens,
      solution: solution,
      difficulty: difficulty,
    );
  }

  /// Calls QQWing on the current thread. Prefer [generate].
  ///
  /// Native buffers are owned by Dart: allocated here, and released in
  /// `finally` whatever happens. The C side only writes into them.
  static (List<int>, List<int>) generateBlocking(
    SudokuDifficulty difficulty,
    int seed, {
    String? libraryPath,
    void Function(QqwingStats stats)? onStats,
  }) {
    final bindings = openQqwing(path: libraryPath);
    final puzzle = calloc<Int32>(QQWING_CELL_COUNT);
    final solution = calloc<Int32>(QQWING_CELL_COUNT);
    final stats = calloc<QqwingStats>();
    try {
      final code = bindings.qqwing_generate(
        nativeDifficulty(difficulty),
        seed,
        puzzle,
        solution,
        stats,
      );
      if (code != QQWING_OK) {
        throw SudokuGenerationException(
          'QQWing failed to generate a ${difficulty.label} puzzle '
          '(error $code).',
        );
      }
      onStats?.call(stats.ref);
      return (
        List<int>.of(puzzle.asTypedList(QQWING_CELL_COUNT)),
        List<int>.of(solution.asTypedList(QQWING_CELL_COUNT)),
      );
    } finally {
      calloc
        ..free(puzzle)
        ..free(solution)
        ..free(stats);
    }
  }

  static int nativeDifficulty(SudokuDifficulty difficulty) =>
      switch (difficulty) {
        SudokuDifficulty.hard => QQWING_DIFFICULTY_HARD,
        SudokuDifficulty.veryHard => QQWING_DIFFICULTY_VERY_HARD,
        SudokuDifficulty.extreme => QQWING_DIFFICULTY_EXTREME,
      };
}

/// The platform's puzzle source (see `qqwing_puzzle_source_stub.dart`).
SudokuPuzzleSource createPuzzleSource() => QqwingPuzzleSource();
