import '../core/game/game_interface.dart';
import 'original_game/original_game.dart';
import 'sudoku/sudoku_game.dart';

/// Every game in the app, in menu order. Add new games here.
abstract final class GameRegistry {
  static const List<GameInterface> all = [OriginalGame(), SudokuGame()];

  static GameInterface? byId(String id) {
    for (final game in all) {
      if (game.id == id) return game;
    }
    return null;
  }
}
