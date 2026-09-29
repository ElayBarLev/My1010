import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/shared_preferences_provider.dart';
import '../data/in_memory_leaderboard_repository.dart';
import '../domain/leaderboard_entry.dart';
import '../domain/leaderboard_repository.dart';

/// Defaults to the offline store; `main()` overrides it with the Firestore
/// implementation once Firebase has initialised successfully.
final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  final repository = InMemoryLeaderboardRepository();
  ref.onDispose(repository.dispose);
  return repository;
});

final topScoresProvider = StreamProvider.autoDispose
    .family<List<LeaderboardEntry>, String>(
      (ref, modeId) => ref
          .watch(leaderboardRepositoryProvider)
          .watchTopScores(modeId: modeId),
    );

/// The name shown on the leaderboard, persisted locally.
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

  Future<void> submit({required String modeId, required int score}) async {
    try {
      await _ref
          .read(leaderboardRepositoryProvider)
          .submitScore(
            modeId: modeId,
            score: score,
            displayName: _ref.read(playerNameProvider),
          );
    } catch (error) {
      debugPrint('Leaderboard submission failed: $error');
    }
  }
}
