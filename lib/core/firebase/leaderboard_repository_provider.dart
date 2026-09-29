import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'in_memory_leaderboard_repository.dart';
import 'leaderboard_repository.dart';

/// Defaults to the offline store; `main()` overrides it with the Firestore
/// implementation once Firebase has initialised successfully.
final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  final repository = InMemoryLeaderboardRepository();
  ref.onDispose(repository.dispose);
  return repository;
});
