import 'dart:async';

import '../domain/leaderboard_entry.dart';
import '../domain/leaderboard_repository.dart';

/// Offline stand-in for the global leaderboard, used when Firebase isn't
/// configured and in tests. Mirrors the Firestore semantics: one entry per
/// player per mode, keeping only the best score.
class InMemoryLeaderboardRepository implements LeaderboardRepository {
  InMemoryLeaderboardRepository({
    this.localUserId = 'local-player',
    Iterable<LeaderboardEntry> seed = const [],
  }) {
    for (final e in seed) {
      _entries.putIfAbsent(e.modeId, () => {})[e.uid] = e;
    }
  }

  final String localUserId;
  final Map<String, Map<String, LeaderboardEntry>> _entries = {};
  final _changes = StreamController<String>.broadcast();

  @override
  bool get isRemote => false;

  @override
  String? get currentUserId => localUserId;

  List<LeaderboardEntry> _top(String modeId, int limit) {
    final list = [...?_entries[modeId]?.values]
      ..sort((a, b) => b.score.compareTo(a.score));
    return list.take(limit).toList(growable: false);
  }

  @override
  Stream<List<LeaderboardEntry>> watchTopScores({
    required String modeId,
    int limit = 50,
  }) async* {
    yield _top(modeId, limit);
    yield* _changes.stream
        .where((changed) => changed == modeId)
        .map((_) => _top(modeId, limit));
  }

  @override
  Future<void> submitScore({
    required String modeId,
    required int score,
    required String displayName,
  }) async {
    if (score <= 0) return;
    final scores = _entries.putIfAbsent(modeId, () => {});
    final previous = scores[localUserId];
    scores[localUserId] = LeaderboardEntry(
      uid: localUserId,
      displayName: LeaderboardEntry.sanitizeName(displayName),
      score: previous == null || score > previous.score
          ? score
          : previous.score,
      modeId: modeId,
      updatedAt: DateTime.now(),
    );
    _changes.add(modeId);
  }

  Future<void> dispose() => _changes.close();
}
