import 'leaderboard_entry.dart';

/// Global high-score storage, shared by every game that
/// `supportsLeaderboard`. Scores live at `leaderboards/{gameId}/scores`.
///
/// Implemented by Firestore in production and by an in-memory store when
/// Firebase isn't configured (and in tests).
abstract interface class LeaderboardRepository {
  /// `true` when scores are shared with other players.
  bool get isRemote;

  /// The id of the signed-in player, if known yet.
  String? get currentUserId;

  /// Highest scores first, updating live.
  Stream<List<LeaderboardEntry>> watchTopScores({
    required String gameId,
    int limit = 50,
  });

  /// Records [score] under [anonymousName] for the current (anonymously
  /// signed-in) player if it beats their previous best for [gameId].
  Future<void> submitScore({
    required String gameId,
    required String anonymousName,
    required int score,
  });
}
