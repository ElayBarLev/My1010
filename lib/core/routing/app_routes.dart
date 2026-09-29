/// Named routes, so features and games can navigate to each other without
/// importing each other's pages. Route names are URL paths, so they also
/// work as deep links on web.
abstract final class AppRoutes {
  static const home = '/';

  static const _gamePrefix = '/games/';
  static const _leaderboardPrefix = '/leaderboard/';

  /// The screen of the game whose `GameInterface.id` is [gameId].
  static String game(String gameId) => '$_gamePrefix$gameId';

  /// The leaderboard of [gameId]. Callers may pass the player's personal
  /// best as the route's `arguments` (an `int`).
  static String leaderboard(String gameId) => '$_leaderboardPrefix$gameId';

  /// The game id in a [game] route name, or `null`.
  static String? gameIdOf(String? name) => _idAfter(_gamePrefix, name);

  /// The game id in a [leaderboard] route name, or `null`.
  static String? leaderboardIdOf(String? name) =>
      _idAfter(_leaderboardPrefix, name);

  static String? _idAfter(String prefix, String? name) {
    if (name == null || !name.startsWith(prefix)) return null;
    final id = name.substring(prefix.length);
    return id.isEmpty || id.contains('/') ? null : id;
  }
}
