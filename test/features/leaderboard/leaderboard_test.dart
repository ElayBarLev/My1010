import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ten_ten_clone/features/leaderboard/data/in_memory_leaderboard_repository.dart';
import 'package:ten_ten_clone/features/leaderboard/domain/leaderboard_entry.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_shapes.dart';

void main() {
  group('InMemoryLeaderboardRepository', () {
    test('keeps only the best score per player and sorts descending', () async {
      final repo = InMemoryLeaderboardRepository(
        seed: const [
          LeaderboardEntry(
            uid: 'a',
            displayName: 'Ada',
            score: 300,
            modeId: 'classic',
          ),
          LeaderboardEntry(
            uid: 'b',
            displayName: 'Bo',
            score: 100,
            modeId: 'classic',
          ),
        ],
      );
      await repo.submitScore(modeId: 'classic', score: 200, displayName: 'Me');
      await repo.submitScore(modeId: 'classic', score: 150, displayName: 'Me');

      final top = await repo.watchTopScores(modeId: 'classic').first;
      expect(top.map((e) => e.score), [300, 200, 100]);
      expect(top[1].uid, repo.localUserId);
      await repo.dispose();
    });

    test('ignores zero scores and separates modes', () async {
      final repo = InMemoryLeaderboardRepository();
      await repo.submitScore(modeId: 'classic', score: 0, displayName: 'Me');
      await repo.submitScore(modeId: 'other', score: 10, displayName: 'Me');
      expect(await repo.watchTopScores(modeId: 'classic').first, isEmpty);
      expect(await repo.watchTopScores(modeId: 'other').first, hasLength(1));
      await repo.dispose();
    });

    test('emits live updates', () async {
      final repo = InMemoryLeaderboardRepository();
      final updates = repo.watchTopScores(modeId: 'classic');
      final expectation = expectLater(
        updates.map((l) => l.length),
        emitsInOrder([0, 1]),
      );
      await Future<void>.delayed(Duration.zero);
      await repo.submitScore(modeId: 'classic', score: 5, displayName: 'Me');
      await expectation;
      await repo.dispose();
    });
  });

  test('display names are trimmed and bounded', () {
    expect(LeaderboardEntry.sanitizeName('   '), 'Player');
    expect(LeaderboardEntry.sanitizeName('  a   b '), 'a b');
    expect(LeaderboardEntry.sanitizeName('x' * 50), hasLength(20));
  });

  testWidgets('leaderboard page shows offline notice and entries', (
    tester,
  ) async {
    final repo = InMemoryLeaderboardRepository(
      seed: const [
        LeaderboardEntry(
          uid: 'a',
          displayName: 'Ada',
          score: 321,
          modeId: 'classic',
        ),
      ],
    );
    await pumpGame(tester, shapes: [dot, square2, line5h], leaderboard: repo);

    await tester.tap(find.byTooltip('Leaderboard'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Offline mode'), findsOneWidget);
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('321'), findsOneWidget);

    await tester.tap(find.byTooltip('Change name'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Elay');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Elay'), findsOneWidget);
  });
}
