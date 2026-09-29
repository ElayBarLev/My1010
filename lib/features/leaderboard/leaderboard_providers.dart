import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firebase/leaderboard_entry.dart';
import '../../core/firebase/leaderboard_repository_provider.dart';
import '../../core/storage/shared_preferences_provider.dart';

final topScoresProvider = StreamProvider.autoDispose
    .family<List<LeaderboardEntry>, String>(
      (ref, gameId) => ref
          .watch(leaderboardRepositoryProvider)
          .watchTopScores(gameId: gameId),
    );

/// The name shown on the leaderboard, persisted locally. Shared by every
/// game; no account is needed.
final playerNameProvider = NotifierProvider<PlayerNameController, String>(
  PlayerNameController.new,
);

class PlayerNameController extends Notifier<String> {
  static const _key = 'player.displayName';

  @override
  String build() =>
      ref.watch(sharedPreferencesProvider).getString(_key) ?? 'Player';

  Future<void> rename(String raw) async {
    state = LeaderboardEntry.sanitizeName(raw);
    await ref.read(sharedPreferencesProvider).setString(_key, state);
  }
}

/// Submits finished games. Failures (offline, rules rejection) are logged
/// and swallowed: the leaderboard must never break the game loop.
final scoreSubmitterProvider = Provider<ScoreSubmitter>(
  (ref) => ScoreSubmitter(ref),
);

class ScoreSubmitter {
  ScoreSubmitter(this._ref);

  final Ref _ref;

  Future<void> submit({required String gameId, required int score}) async {
    try {
      await _ref
          .read(leaderboardRepositoryProvider)
          .submitScore(
            gameId: gameId,
            anonymousName: _ref.read(playerNameProvider),
            score: score,
          );
    } catch (error) {
      debugPrint('Leaderboard submission failed: $error');
    }
  }
}
