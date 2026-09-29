import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/game/game_interface.dart';
import '../../features/leaderboard/leaderboard_name_entry.dart';
import '../../features/leaderboard/leaderboard_providers.dart';
import 'domain/entities/game_state.dart';
import 'domain/game_mode.dart';
import 'presentation/controllers/game_controller.dart';
import 'presentation/pages/game_page.dart';

/// The original 1010! block puzzle.
class OriginalGame extends GameInterface {
  const OriginalGame();

  /// Kept equal to the classic mode's id so the leaderboard bucket
  /// (`leaderboards/classic/scores`) and existing scores stay valid.
  @override
  String get id => GameModes.classic.id;

  @override
  String get displayName => '1010!';

  @override
  IconData get menuIcon => Icons.grid_view_rounded;

  @override
  bool get supportsLeaderboard => true;

  @override
  Widget buildGameScreen() => const OriginalGameScreen();
}

/// [GamePage] plus its leaderboard wiring: finished games are submitted
/// automatically, and the game-over overlay offers a name field.
class OriginalGameScreen extends ConsumerWidget {
  const OriginalGameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<GameState>(gameControllerProvider, (previous, next) {
      if (next.isGameOver && !(previous?.isGameOver ?? false)) {
        ref
            .read(scoreSubmitterProvider)
            .submit(gameId: next.modeId, score: next.score);
      }
    });

    return GamePage(
      gameOverExtra: Consumer(
        builder: (context, ref, _) {
          final game = ref.watch(gameControllerProvider);
          return LeaderboardNameEntry(gameId: game.modeId, score: game.score);
        },
      ),
    );
  }
}
