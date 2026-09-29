import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my1010/core/firebase/in_memory_leaderboard_repository.dart';
import 'package:my1010/games/original_game/domain/entities/grid_point.dart';
import 'package:my1010/games/original_game/presentation/controllers/game_controller.dart';
import 'package:my1010/core/firebase/leaderboard_entry.dart';
import 'package:my1010/features/leaderboard/leaderboard_name_entry.dart';

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
            gameId: 'classic',
          ),
          LeaderboardEntry(
            uid: 'b',
            displayName: 'Bo',
            score: 100,
            gameId: 'classic',
          ),
        ],
      );
      await repo.submitScore(
        gameId: 'classic',
        anonymousName: 'Me',
        score: 200,
      );
      await repo.submitScore(
        gameId: 'classic',
        anonymousName: 'Me',
        score: 150,
      );

      final top = await repo.watchTopScores(gameId: 'classic').first;
      expect(top.map((e) => e.score), [300, 200, 100]);
      expect(top[1].uid, repo.localUserId);
      await repo.dispose();
    });

    test('ignores zero scores and separates modes', () async {
      final repo = InMemoryLeaderboardRepository();
      await repo.submitScore(gameId: 'classic', anonymousName: 'Me', score: 0);
      await repo.submitScore(gameId: 'other', anonymousName: 'Me', score: 10);
      expect(await repo.watchTopScores(gameId: 'classic').first, isEmpty);
      expect(await repo.watchTopScores(gameId: 'other').first, hasLength(1));
      await repo.dispose();
    });

    test('emits live updates', () async {
      final repo = InMemoryLeaderboardRepository();
      final updates = repo.watchTopScores(gameId: 'classic');
      final expectation = expectLater(
        updates.map((l) => l.length),
        emitsInOrder([0, 1]),
      );
      await Future<void>.delayed(Duration.zero);
      await repo.submitScore(gameId: 'classic', anonymousName: 'Me', score: 5);
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
          gameId: 'classic',
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

  testWidgets('players name themselves on game over without logging in', (
    tester,
  ) async {
    final repo = InMemoryLeaderboardRepository();
    final container = await pumpGame(
      tester,
      shapes: [square3, square3, square3],
      leaderboard: repo,
    );
    final controller = container.read(gameControllerProvider.notifier);
    for (final r in const [0, 3, 6]) {
      for (final c in const [0, 3, 6]) {
        controller.place((r + c ~/ 3) % 3, GridPoint(r, c));
      }
    }
    await tester.pumpAndSettle();
    expect(container.read(gameControllerProvider).isGameOver, isTrue);

    // Score was auto-submitted under the default name.
    var top = await repo.watchTopScores(gameId: 'classic').first;
    expect(top.single.displayName, 'Player');

    await tester.enterText(find.byKey(LeaderboardNameEntry.fieldKey), ' Elay ');
    await tester.tap(find.byKey(LeaderboardNameEntry.saveKey));
    await tester.pumpAndSettle();

    top = await repo.watchTopScores(gameId: 'classic').first;
    expect(top.single.displayName, 'Elay');
    expect(top.single.score, 81);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });
}
