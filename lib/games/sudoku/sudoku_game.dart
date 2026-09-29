import 'package:flutter/material.dart';

import '../../core/game/game_interface.dart';
import 'data/puzzle_source.dart';
import 'presentation/pages/sudoku_page.dart';

/// Classic 9×9 Sudoku with puzzles generated on the device by QQWing.
class SudokuGame extends GameInterface {
  const SudokuGame();

  @override
  String get id => 'sudoku';

  @override
  String get displayName => 'Sudoku';

  @override
  IconData get menuIcon => Icons.grid_on_rounded;

  /// Sudoku has no score to rank, only a solved / unsolved outcome.
  @override
  bool get supportsLeaderboard => false;

  /// Needs the native QQWing library (not available on web).
  @override
  bool get isAvailable => defaultPuzzleSource.isAvailable;

  @override
  Widget buildGameScreen() => const SudokuPage();
}
