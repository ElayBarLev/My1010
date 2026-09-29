import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'leaderboard_entry.dart';
import 'leaderboard_repository.dart';

/// Firestore-backed global leaderboard.
///
/// Layout: `leaderboards/{gameId}/scores/{uid}` — one document per player
/// per game holding their best score. Players are signed in anonymously the
/// first time they submit, so no sign-up flow is needed; `firestore.rules`
/// restricts every write to the caller's own document and only allows the
/// score to go up.
class FirestoreLeaderboardRepository implements LeaderboardRepository {
  FirestoreLeaderboardRepository({required this.firestore, required this.auth});

  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  CollectionReference<Map<String, dynamic>> _scores(String gameId) =>
      firestore.collection('leaderboards').doc(gameId).collection('scores');

  @override
  bool get isRemote => true;

  @override
  String? get currentUserId => auth.currentUser?.uid;

  Future<User> _ensureSignedIn() async {
    final existing = auth.currentUser;
    if (existing != null) return existing;
    final credential = await auth.signInAnonymously();
    return credential.user!;
  }

  @override
  Stream<List<LeaderboardEntry>> watchTopScores({
    required String gameId,
    int limit = 50,
  }) =>
      _scores(gameId)
          .orderBy('score', descending: true)
          .limit(limit)
          .snapshots()
          .map((snap) => [for (final doc in snap.docs) _fromDoc(doc, gameId)]);

  @override
  Future<void> submitScore({
    required String gameId,
    required String anonymousName,
    required int score,
  }) async {
    if (score <= 0) return;
    final user = await _ensureSignedIn();
    final doc = _scores(gameId).doc(user.uid);
    final name = LeaderboardEntry.sanitizeName(anonymousName);

    await firestore.runTransaction((tx) async {
      final snap = await tx.get(doc);
      final previous = (snap.data()?['score'] as num?)?.toInt() ?? 0;
      if (snap.exists && previous >= score) {
        // Keep the best score, but let a renamed player update their name.
        if (snap.data()?['displayName'] != name) {
          tx.update(doc, {
            'displayName': name,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        return;
      }
      tx.set(doc, {
        'uid': user.uid,
        'displayName': name,
        'score': score,
        // Field name predates multi-game support; `firestore.rules` checks
        // it against the `{modeId}` path segment, which is the game id.
        'modeId': gameId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  static LeaderboardEntry _fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String gameId,
  ) {
    final data = doc.data();
    return LeaderboardEntry(
      uid: doc.id,
      displayName: data['displayName'] as String? ?? 'Player',
      score: (data['score'] as num?)?.toInt() ?? 0,
      gameId: data['modeId'] as String? ?? gameId,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
