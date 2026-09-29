import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/game_state.dart';
import '../domain/game_mode.dart';

/// Saves the in-progress game and the local best score, one slot per mode.
class GameStateRepository {
  GameStateRepository(this._prefs);

  final SharedPreferences _prefs;

  static String saveKey(String modeId) => 'game.$modeId.save';
  static String bestKey(String modeId) => 'game.$modeId.best';

  /// Returns `null` if there is no save or it can't be read (e.g. written by
  /// an incompatible version); a corrupt save is discarded, never fatal.
  GameState? loadGame(GameMode mode) {
    final raw = _prefs.getString(saveKey(mode.id));
    if (raw == null) return null;
    try {
      final state = GameState.fromJson(
        jsonDecode(raw) as Map<String, Object?>,
        catalog: mode.catalog,
        bestScore: loadBestScore(mode.id),
      );
      if (state.modeId != mode.id || state.board.size != mode.boardSize) {
        return null;
      }
      return state;
    } catch (error) {
      debugPrint('Discarding unreadable save for ${mode.id}: $error');
      return null;
    }
  }

  Future<void> saveGame(GameState state) =>
      _prefs.setString(saveKey(state.modeId), jsonEncode(state.toJson()));

  Future<void> clearGame(String modeId) => _prefs.remove(saveKey(modeId));

  int loadBestScore(String modeId) => _prefs.getInt(bestKey(modeId)) ?? 0;

  Future<void> saveBestScore(String modeId, int score) async {
    if (score > loadBestScore(modeId)) {
      await _prefs.setInt(bestKey(modeId), score);
    }
  }
}
