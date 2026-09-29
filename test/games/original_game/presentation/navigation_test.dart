import 'package:flutter_test/flutter_test.dart';
import 'package:my1010/features/home/home_page.dart';
import 'package:my1010/features/leaderboard/leaderboard_page.dart';
import 'package:my1010/games/original_game/presentation/widgets/board_grid.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/test_shapes.dart';

void main() {
  testWidgets('the menu button returns to the game menu', (tester) async {
    await pumpGame(tester, shapes: [dot, square2, line5h]);

    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();

    expect(find.byType(BoardGrid), findsNothing);
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('the leaderboard opens for the classic mode with the best', (
    tester,
  ) async {
    await pumpGame(
      tester,
      shapes: [dot, square2, line5h],
      prefs: {'game.classic.best': 420},
    );

    await tester.tap(find.byTooltip('Leaderboard'));
    await tester.pumpAndSettle();

    final page = tester.widget<LeaderboardPage>(find.byType(LeaderboardPage));
    expect(page.gameId, 'classic');
    expect(page.personalBest, 420);
    expect(find.text('1010! leaderboard'), findsOneWidget);
    expect(find.text('Personal best 420'), findsOneWidget);
  });
}
