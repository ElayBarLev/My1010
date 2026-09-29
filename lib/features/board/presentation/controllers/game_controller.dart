import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/shared_preferences_provider.dart';
import '../../data/game_state_repository.dart';
import '../../domain/entities/game_state.dart';
import '../../domain/entities/grid_point.dart';
import '../../domain/game_engine.dart';
import '../../domain/game_mode.dart';

/// The active game mode. Override (or turn into a mode picker) to add modes.
final gameModeProvider = Provider<GameMode>((ref) => GameModes.classic);

final gameEngineProvider = Provider<GameEngine>(
  (ref) => GameEngine(mode: ref.watch(gameModeProvider), random: Random()),
);

final gameStateRepositoryProvider = Provider<GameStateRepository>(
  (ref) => GameStateRepository(ref.watch(sharedPreferencesProvider)),
);

final gameControllerProvider = NotifierProvider<GameController, GameState>(
  GameController.new,
);

/// Bridges the pure [GameEngine] to the UI and persists every move.
class GameController extends Notifier<GameState> {
  GameEngine get _engine => ref.read(gameEngineProvider);
  GameStateRepository get _repository => ref.read(gameStateRepositoryProvider);

  @override
  GameState build() {
    final mode = ref.watch(gameModeProvider);
    ref.watch(gameEngineProvider);
    final repository = ref.watch(gameStateRepositoryProvider);

    final saved = repository.loadGame(mode);
    if (saved != null && !saved.isGameOver) return saved;
    return ref
        .read(gameEngineProvider)
        .newGame(bestScore: repository.loadBestScore(mode.id));
  }

  PlacementPreview? preview(int slot, GridPoint origin) =>
      _engine.preview(state, slot, origin);

  /// Attempts a move; returns whether it was applied.
  bool place(int slot, GridPoint origin) {
    final next = _engine.place(state, slot, origin);
    if (next == null) return false;
    state = next;
    unawaited(_persist(next));
    return true;
  }

  void restart() {
    state = _engine.newGame(bestScore: state.bestScore);
    unawaited(_repository.clearGame(state.modeId));
  }

  Future<void> _persist(GameState next) async {
    await _repository.saveBestScore(next.modeId, next.bestScore);
    if (next.isGameOver) {
      await _repository.clearGame(next.modeId);
    } else {
      await _repository.saveGame(next);
    }
  }
}
