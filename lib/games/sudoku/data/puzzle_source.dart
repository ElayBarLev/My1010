import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/sudoku_puzzle.dart';
// The only door into the FFI module: nothing outside lib/games/sudoku may
// import ffi/ (test/architecture_test.dart checks this). The stub keeps
// dart:ffi out of web builds.
import '../ffi/qqwing_puzzle_source_stub.dart'
    if (dart.library.ffi) '../ffi/qqwing_puzzle_source.dart'
    as platform;

/// The platform's generator: QQWing over dart:ffi, or an unavailable stub
/// on web. Created (and the native library probed) on first use.
final SudokuPuzzleSource defaultPuzzleSource = platform.createPuzzleSource();

/// Override in tests with a scripted source.
final sudokuPuzzleSourceProvider = Provider<SudokuPuzzleSource>(
  (ref) => defaultPuzzleSource,
);
