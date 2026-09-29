import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/game/game_interface.dart';
import 'core/routing/app_routes.dart';
import 'core/ui_kit/theme/theme_controller.dart';
import 'features/home/home_page.dart';
import 'features/leaderboard/leaderboard_page.dart';
import 'games/game_registry.dart';

class TenTenApp extends ConsumerWidget {
  const TenTenApp({super.key, this.games = GameRegistry.all});

  /// The games in the menu; tests may pass a subset.
  final List<GameInterface> games;

  GameInterface? _game(String? id) {
    if (id == null) return null;
    for (final game in games) {
      if (game.id == id) return game;
    }
    return null;
  }

  /// Composition root: the home menu, every game's screen and the shared
  /// leaderboard are wired together here, so none of them import each other.
  Route<void>? _onGenerateRoute(RouteSettings settings) {
    final name = settings.name;
    final Widget? page;
    if (name == AppRoutes.home) {
      page = HomePage(games: games);
    } else if (_game(AppRoutes.gameIdOf(name)) case final game?
        when game.isAvailable) {
      page = game.buildGameScreen();
    } else if (AppRoutes.leaderboardIdOf(name) case final gameId?) {
      page = LeaderboardPage(
        gameId: gameId,
        title: _game(gameId)?.displayName ?? gameId,
        personalBest: settings.arguments as int?,
      );
    } else {
      page = null;
    }
    if (page == null) return null;
    return MaterialPageRoute<void>(settings: settings, builder: (_) => page!);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(paletteProvider);
    return MaterialApp(
      title: 'my1010',
      debugShowCheckedModeBanner: false,
      theme: palette.toThemeData(),
      initialRoute: AppRoutes.home,
      onGenerateRoute: _onGenerateRoute,
      onUnknownRoute: (settings) => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => HomePage(games: games),
      ),
    );
  }
}
