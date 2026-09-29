import 'package:flutter_test/flutter_test.dart';
import 'package:my1010/core/routing/app_routes.dart';

void main() {
  test('game and leaderboard routes round-trip their game id', () {
    expect(AppRoutes.gameIdOf(AppRoutes.game('sudoku')), 'sudoku');
    expect(
      AppRoutes.leaderboardIdOf(AppRoutes.leaderboard('classic')),
      'classic',
    );
  });

  test('malformed routes have no game id', () {
    expect(AppRoutes.gameIdOf(AppRoutes.home), isNull);
    expect(AppRoutes.gameIdOf('/games/'), isNull);
    expect(AppRoutes.gameIdOf('/games/a/b'), isNull);
    expect(AppRoutes.leaderboardIdOf(AppRoutes.game('classic')), isNull);
    expect(AppRoutes.gameIdOf(null), isNull);
  });
}
