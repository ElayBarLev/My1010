import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my1010/app.dart';
import 'package:my1010/core/game/game_interface.dart';
import 'package:my1010/core/storage/shared_preferences_provider.dart';
import 'package:my1010/features/home/home_page.dart';
import 'package:my1010/features/leaderboard/leaderboard_page.dart';
import 'package:my1010/games/game_registry.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeGame extends GameInterface {
  const _FakeGame(
    this.id, {
    this.supportsLeaderboard = false,
    this.isAvailable = true,
  });

  @override
  final String id;

  @override
  final bool supportsLeaderboard;

  @override
  final bool isAvailable;

  @override
  String get displayName => 'Game $id';

  @override
  IconData get menuIcon => Icons.star;

  @override
  Widget buildGameScreen() =>
      Scaffold(body: Text('screen of $id', key: ValueKey('screen-$id')));
}

Future<void> _pumpApp(WidgetTester tester, List<GameInterface> games) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: TenTenApp(games: games),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('registered games have unique ids', () {
    final ids = GameRegistry.all.map((g) => g.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
    expect(GameRegistry.byId(ids.first), same(GameRegistry.all.first));
    expect(GameRegistry.byId('missing'), isNull);
  });

  testWidgets('the menu lists every game and opens the tapped one', (
    tester,
  ) async {
    await _pumpApp(tester, const [_FakeGame('a'), _FakeGame('b')]);

    expect(find.text('Game a'), findsOneWidget);
    expect(find.text('Game b'), findsOneWidget);

    await tester.tap(find.byKey(HomePage.tileKey('b')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-b')), findsOneWidget);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('leaderboard shortcut only for games that support it', (
    tester,
  ) async {
    await _pumpApp(tester, const [
      _FakeGame('ranked', supportsLeaderboard: true),
      _FakeGame('casual'),
    ]);

    expect(find.byTooltip('Game ranked leaderboard'), findsOneWidget);
    expect(find.byTooltip('Game casual leaderboard'), findsNothing);

    await tester.tap(find.byTooltip('Game ranked leaderboard'));
    await tester.pumpAndSettle();
    final page = tester.widget<LeaderboardPage>(find.byType(LeaderboardPage));
    expect(page.gameId, 'ranked');
    expect(find.text('Game ranked leaderboard'), findsOneWidget);
  });

  testWidgets('unavailable games are shown disabled', (tester) async {
    await _pumpApp(tester, const [_FakeGame('native', isAvailable: false)]);

    expect(find.text('Not available on this platform'), findsOneWidget);
    await tester.tap(find.byKey(HomePage.tileKey('native')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-native')), findsNothing);
  });
}
