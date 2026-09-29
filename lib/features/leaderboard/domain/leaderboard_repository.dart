import 'leaderboard_entry.dart';

/// Global high-score storage. Implemented by Firestore in production and by
/// an in-memory store when Firebase isn't configured (and in tests).
abstract interface class LeaderboardRepository {
  /// `true` when scores are shared with other players.
  bool get isRemote;

  /// The id of the signed-in player, if known yet.
  String? get currentUserId;

  /// Highest scores first, updating live.
  Stream<List<LeaderboardEntry>> watchTopScores({
    required String modeId,
    int limit = 50,
  });

  /// Records [score] for the current player if it beats their previous best.
  Future<void> submitScore({
    required String modeId,
    required int score,
    required String displayName,
  });
}
