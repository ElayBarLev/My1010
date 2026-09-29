import 'dart:async';

import 'leaderboard_entry.dart';
import 'leaderboard_repository.dart';

/// Offline stand-in for the global leaderboard, used when Firebase isn't
/// configured and in tests. Mirrors the Firestore semantics: one entry per
/// player per game, keeping only the best score.
class InMemoryLeaderboardRepository implements LeaderboardRepository {
  InMemoryLeaderboardRepository({
    this.localUserId = 'local-player',
    Iterable<LeaderboardEntry> seed = const [],
  }) {
    for (final e in seed) {
      _entries.putIfAbsent(e.gameId, () => {})[e.uid] = e;
    }
  }

  final String localUserId;
  final Map<String, Map<String, LeaderboardEntry>> _entries = {};
  final _changes = StreamController<String>.broadcast();

  @override
  bool get isRemote => false;

  @override
  String? get currentUserId => localUserId;

  List<LeaderboardEntry> _top(String gameId, int limit) {
    final list = [...?_entries[gameId]?.values]
      ..sort((a, b) => b.score.compareTo(a.score));
    return list.take(limit).toList(growable: false);
  }

  @override
  Stream<List<LeaderboardEntry>> watchTopScores({
    required String gameId,
    int limit = 50,
  }) async* {
    yield _top(gameId, limit);
    yield* _changes.stream
        .where((changed) => changed == gameId)
        .map((_) => _top(gameId, limit));
  }

  @override
  Future<void> submitScore({
    required String gameId,
    required String anonymousName,
    required int score,
  }) async {
    if (score <= 0) return;
    final scores = _entries.putIfAbsent(gameId, () => {});
    final previous = scores[localUserId];
    scores[localUserId] = LeaderboardEntry(
      uid: localUserId,
      displayName: LeaderboardEntry.sanitizeName(anonymousName),
      score: previous == null || score > previous.score
          ? score
          : previous.score,
      gameId: gameId,
      updatedAt: DateTime.now(),
    );
    _changes.add(gameId);
  }

  Future<void> dispose() => _changes.close();
}
